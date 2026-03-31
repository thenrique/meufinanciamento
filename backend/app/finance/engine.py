from abc import ABC, abstractmethod
from typing import Optional, List, Dict, Tuple
from datetime import date, timedelta, datetime, timezone
import pandas as pd
from loguru import logger
from app.finance.bcb_service import get_tr_mensal
from app.finance.services.tr_cache import get_tr_historical, get_tr_for_month
from app.finance.models import (
    CalculatedMonthEntry,
    ActualMonthEntry,
    ComparisonSummary,
    LoanWithPaymentHistory,
    PaymentRecord,
)


class BankModel(ABC):
    """Modelo base para cálculo de financiamentos bancários."""

    @abstractmethod
    async def calculate_schedule(
        self,
        balance: float,
        annual_rate: float,
        months: int,
        insurance_monthly: float,
        extra_monthly: float = 0.0,
        extra_one_time: float = 0.0,
    ) -> pd.DataFrame:
        """Gera tabela de amortização."""
        ...


class CaixaModel(BankModel):
    """
    Implementa o sistema SAC com TR, padrão Caixa Econômica Federal.
    A parcela decresce mensalmente pois a amortização é constante.
    """

    async def calculate_schedule(
        self,
        balance: float,
        annual_rate: float,
        months: int,
        insurance_monthly: float,
        extra_monthly: float = 0.0,
        extra_one_time: float = 0.0,
    ) -> pd.DataFrame:
        """
        Gera a tabela SAC com TR.

        Args:
            balance: Saldo devedor atual em R$.
            annual_rate: Taxa de juros anual contratada (%).
            months: Prazo restante em meses.
            insurance_monthly: Valor mensal do seguro em R$.
            extra_monthly: Aporte extra mensal em R$.
            extra_one_time: Aporte extra pontual no primeiro mês em R$.

        Returns:
            DataFrame com colunas: mes, saldo_inicial, amortizacao, juros, prestacao,
            aporte_extra, saldo_final.
        """
        tr_mensal = await get_tr_mensal()
        taxa_mensal = (1 + annual_rate / 100) ** (1 / 12) - 1
        taxa_efetiva_mensal = (1 + taxa_mensal) * (1 + tr_mensal / 100) - 1

        rows = []
        saldo = balance
        meses_restantes = months

        for mes in range(1, months + 1):
            if saldo <= 0:
                break

            saldo_inicial = saldo
            aporte = extra_monthly
            if mes == 1:
                aporte += extra_one_time

            if aporte > 0:
                saldo = max(0.0, saldo - aporte)
                if saldo == 0:
                    rows.append({
                        "mes": mes,
                        "saldo_inicial": saldo_inicial,
                        "amortizacao": saldo_inicial,
                        "juros": 0.0,
                        "prestacao": saldo_inicial,
                        "aporte_extra": aporte,
                        "saldo_final": 0.0,
                    })
                    break
                meses_restantes = months - mes + 1

            amortizacao = saldo / meses_restantes
            juros = saldo * taxa_efetiva_mensal
            prestacao = amortizacao + juros + insurance_monthly
            saldo_final = max(0.0, saldo - amortizacao)

            rows.append({
                "mes": mes,
                "saldo_inicial": saldo_inicial,
                "amortizacao": round(amortizacao, 2),
                "juros": round(juros, 2),
                "prestacao": round(prestacao, 2),
                "aporte_extra": round(aporte, 2),
                "saldo_final": round(saldo_final, 2),
            })

            saldo = saldo_final
            meses_restantes -= 1

        return pd.DataFrame(rows)

    async def compare_scenarios(
        self,
        balance: float,
        annual_rate: float,
        months: int,
        insurance_monthly: float,
        extra_monthly: float = 0.0,
        extra_one_time: float = 0.0,
    ) -> dict:
        """
        Compara cenário base com cenário de aportes extras.

        Returns:
            Dict com cenario_base, cenario_com_aporte e resumo comparativo.
        """
        df_base = await self.calculate_schedule(balance, annual_rate, months, insurance_monthly)
        df_aporte = await self.calculate_schedule(
            balance, annual_rate, months, insurance_monthly, extra_monthly, extra_one_time
        )

        total_juros_base = df_base["juros"].sum()
        total_juros_aporte = df_aporte["juros"].sum()
        total_pago_base = df_base["prestacao"].sum()
        total_pago_aporte = df_aporte["prestacao"].sum() + df_aporte["aporte_extra"].sum()

        meses_base = len(df_base)
        meses_aporte = len(df_aporte)

        return {
            "cenario_base": df_base.to_dict(orient="records"),
            "cenario_com_aporte": df_aporte.to_dict(orient="records"),
            "resumo": {
                "meses_economizados": meses_base - meses_aporte,
                "total_juros_base": round(total_juros_base, 2),
                "total_juros_aporte": round(total_juros_aporte, 2),
                "total_juros_economizados": round(total_juros_base - total_juros_aporte, 2),
                "total_pago_base": round(total_pago_base, 2),
                "total_pago_aporte": round(total_pago_aporte, 2),
                "economia_total": round(total_pago_base - total_pago_aporte, 2),
                "data_quitacao_base": meses_base,
                "data_quitacao_aporte": meses_aporte,
            },
        }


async def calculate_loan_with_history(
    loan: Dict,
    payment_records: List[PaymentRecord],
) -> LoanWithPaymentHistory:
    """
    Calculate estimated vs actual loan amortization.
    
    Reconciles the original contract schedule with actual payments made,
    generating both scenarios and a detailed comparison summary.
    
    Args:
        loan: Loan object with fields: id, name, outstanding_balance, interest_rate_year,
              term_months, insurance_monthly, start_date
        payment_records: List of actual payments made on the loan
    
    Returns:
        LoanWithPaymentHistory with calculated_history, actual_history, and summary
    
    Edge cases handled:
        - Loan already paid off (balance <= 0)
        - No payment records (use estimated schedule as actual)
        - Future payments (include up to today only)
        - Missing TR data (use DEFAULT_TR_VALUE from tr_cache)
        - Very old loans (> 10 years) - limit calculation
    """
    logger.info(f"Calculating loan history for loan {loan['id']}")
    
    try:
        # Step 1: Generate Calculated Scenario (Estimado)
        calculated_history = await _generate_calculated_history(loan)
        
        # Step 2: Generate Actual Scenario (Realizado)
        actual_history = await _generate_actual_history(loan, payment_records, calculated_history)
        
        # Step 3: Generate Comparison Summary
        summary = _generate_comparison_summary(calculated_history, actual_history)
        
        result = LoanWithPaymentHistory(
            loan_id=str(loan['id']),
            loan_name=loan.get('name', 'Financiamento'),
            calculated_history=calculated_history,
            actual_history=actual_history,
            summary=summary,
        )
        
        logger.info(f"Successfully calculated history for loan {loan['id']}")
        return result
        
    except Exception as e:
        logger.error(f"Error calculating loan history for {loan['id']}: {e}")
        raise


async def _generate_calculated_history(loan: Dict) -> List[CalculatedMonthEntry]:
    """
    Generate the calculated/estimated amortization schedule (original contract).
    
    Uses SAC model with TR to calculate month-by-month schedule from start_date
    until payoff without any extra payments.
    """
    start_date = loan['start_date']
    if isinstance(start_date, str):
        start_date = datetime.fromisoformat(start_date).date() if 'T' in start_date else date.fromisoformat(start_date)
    
    balance = loan['outstanding_balance']
    annual_rate = loan['interest_rate_year']
    months = loan['term_months']
    insurance_monthly = loan.get('insurance_monthly', 0.0)
    
    logger.debug(f"Generating calculated history: balance={balance}, rate={annual_rate}%, months={months}")
    
    # Get TR rates for the entire period
    today = date.today()
    tr_data = await get_tr_historical(start_date, today + timedelta(days=365))
    
    rows: List[CalculatedMonthEntry] = []
    current_balance = balance
    current_date = start_date
    month_number = 1
    months_remaining = months
    
    # Calculate effective monthly rate
    taxa_mensal = (1 + annual_rate / 100) ** (1 / 12) - 1
    
    for month_num in range(1, months + 1):
        if current_balance <= 0.01:  # Account for floating point precision
            break
        
        # Get TR for this month (use end of month as reference)
        if current_date.month == 12:
            month_end = date(current_date.year + 1, 1, 1) - timedelta(days=1)
        else:
            month_end = date(current_date.year, current_date.month + 1, 1) - timedelta(days=1)
        
        tr_value = tr_data.get(month_end, 0.0)
        taxa_efetiva_mensal = (1 + taxa_mensal) * (1 + tr_value / 100) - 1
        
        # SAC: amortization is constant
        amortization = current_balance / months_remaining
        interest = current_balance * taxa_efetiva_mensal
        payment = amortization + interest + insurance_monthly
        
        new_balance = max(0.0, current_balance - amortization)
        
        entry = CalculatedMonthEntry(
            month=month_number,
            date=current_date,
            payment_planned=round(payment, 2),
            amortization=round(amortization, 2),
            interest=round(interest, 2),
            insurance=round(insurance_monthly, 2),
            outstanding_balance=round(new_balance, 2),
        )
        
        rows.append(entry)
        
        current_balance = new_balance
        current_date = _add_months(current_date, 1)
        month_number += 1
        months_remaining -= 1
    
    logger.debug(f"Generated {len(rows)} calculated months for loan")
    return rows


async def _generate_actual_history(
    loan: Dict,
    payment_records: List[PaymentRecord],
    calculated_history: List[CalculatedMonthEntry],
) -> List[ActualMonthEntry]:
    """
    Generate the actual amortization history with real payments.
    
    Applies actual payments from payment_records to calculate real balance,
    interest, and amortization month by month.
    """
    start_date = loan['start_date']
    if isinstance(start_date, str):
        start_date = datetime.fromisoformat(start_date).date() if 'T' in start_date else date.fromisoformat(start_date)
    
    balance = loan['outstanding_balance']
    annual_rate = loan['interest_rate_year']
    insurance_monthly = loan.get('insurance_monthly', 0.0)
    
    logger.debug(f"Generating actual history with {len(payment_records)} payments")
    
    # Filter payments: only those on or before today
    today = date.today()
    valid_payments = [p for p in payment_records if p.payment_date <= today]
    
    if not valid_payments:
        logger.warning(f"No valid payments found for loan {loan['id']}, using calculated as actual")
        # Return calculated history as actual with zero deviation
        return [
            ActualMonthEntry(
                month=entry.month,
                date=entry.date,
                payment_planned=entry.payment_planned,
                payment_actual=entry.payment_planned,
                amortization=entry.amortization,
                interest=entry.interest,
                insurance=entry.insurance,
                outstanding_balance=entry.outstanding_balance,
                payments=[],
                deviation=0.0,
            )
            for entry in calculated_history
        ]
    
    # Get TR rates
    tr_data = await get_tr_historical(start_date, today)
    
    rows: List[ActualMonthEntry] = []
    current_balance = balance
    current_date = start_date
    month_number = 1
    
    # Group payments by month
    payments_by_month: Dict[Tuple[int, int], List[PaymentRecord]] = {}
    for payment in valid_payments:
        key = (payment.payment_date.year, payment.payment_date.month)
        if key not in payments_by_month:
            payments_by_month[key] = []
        payments_by_month[key].append(payment)
    
    # Calculate effective monthly rate
    taxa_mensal = (1 + annual_rate / 100) ** (1 / 12) - 1
    
    # Iterate through months up to today
    while current_date <= today and current_balance > 0.01:
        month_key = (current_date.year, current_date.month)
        
        # Get TR for this month
        if current_date.month == 12:
            month_end = date(current_date.year + 1, 1, 1) - timedelta(days=1)
        else:
            month_end = date(current_date.year, current_date.month + 1, 1) - timedelta(days=1)
        
        # Cap month_end to today to avoid future dates
        if month_end > today:
            month_end = today
        
        tr_value = tr_data.get(month_end, 0.0)
        taxa_efetiva_mensal = (1 + taxa_mensal) * (1 + tr_value / 100) - 1
        
        # Calculate interest and insurance for this month
        interest = current_balance * taxa_efetiva_mensal
        
        # Get actual payments for this month
        month_payments = payments_by_month.get(month_key, [])
        actual_payment = sum(p.amount_paid for p in month_payments)
        
        # Calculate amortization: payment - interest - insurance
        # If no payment, amortization is 0
        amortization = max(0.0, actual_payment - interest - insurance_monthly)
        
        # Update balance
        new_balance = max(0.0, current_balance - amortization)
        
        # Get planned payment from calculated history (find closest match)
        planned_entry = None
        for calc in calculated_history:
            if calc.date.year == current_date.year and calc.date.month == current_date.month:
                planned_entry = calc
                break
        
        if not planned_entry:
            planned_payment = 0.0
        else:
            planned_payment = planned_entry.payment_planned
        
        deviation = actual_payment - planned_payment
        
        entry = ActualMonthEntry(
            month=month_number,
            date=current_date,
            payment_planned=round(planned_payment, 2),
            payment_actual=round(actual_payment, 2),
            amortization=round(amortization, 2),
            interest=round(interest, 2),
            insurance=round(insurance_monthly, 2),
            outstanding_balance=round(new_balance, 2),
            payments=month_payments,
            deviation=round(deviation, 2),
        )
        
        rows.append(entry)
        
        current_balance = new_balance
        current_date = _add_months(current_date, 1)
        month_number += 1
    
    logger.debug(f"Generated {len(rows)} actual months for loan")
    return rows


def _generate_comparison_summary(
    calculated_history: List[CalculatedMonthEntry],
    actual_history: List[ActualMonthEntry],
) -> ComparisonSummary:
    """
    Generate summary comparison between estimated and actual scenarios.
    """
    # Calculate totals
    total_payment_planned = sum(m.payment_planned for m in calculated_history)
    total_payment_actual = sum(m.payment_actual for m in actual_history)
    total_interest_planned = sum(m.interest for m in calculated_history)
    total_interest_actual = sum(m.interest for m in actual_history)
    total_insurance = sum(m.insurance for m in actual_history)
    
    months_planned = len(calculated_history)
    months_actual = len(actual_history)
    
    # Count months ahead/behind
    months_ahead = 0
    months_behind = 0
    
    for i, actual in enumerate(actual_history):
        if i < len(calculated_history):
            calc = calculated_history[i]
            if actual.payment_actual > calc.payment_planned:
                months_ahead += 1
            elif actual.payment_actual < calc.payment_planned:
                months_behind += 1
    
    # Get payoff dates
    payoff_date_planned = calculated_history[-1].date if calculated_history else None
    payoff_date_actual = actual_history[-1].date if actual_history else None
    
    # Calculate days ahead
    days_ahead = 0
    if payoff_date_planned and payoff_date_actual:
        delta = payoff_date_planned - payoff_date_actual
        days_ahead = delta.days
    
    total_interest_saved = total_interest_planned - total_interest_actual
    total_deviation = total_payment_actual - total_payment_planned
    
    return ComparisonSummary(
        total_payment_planned=round(total_payment_planned, 2),
        total_payment_actual=round(total_payment_actual, 2),
        total_interest_planned=round(total_interest_planned, 2),
        total_interest_actual=round(total_interest_actual, 2),
        total_interest_saved=round(total_interest_saved, 2),
        total_insurance=round(total_insurance, 2),
        months_planned=months_planned,
        months_actual=months_actual,
        months_ahead=days_ahead // 30 if days_ahead > 0 else (months_ahead - months_behind),
        payoff_date_planned=payoff_date_planned,
        payoff_date_actual=payoff_date_actual,
        days_ahead=days_ahead,
        total_deviation=round(total_deviation, 2),
    )


def _add_months(d: date, months: int) -> date:
    """Add months to a date, handling month/year boundaries."""
    month = d.month - 1 + months
    year = d.year + month // 12
    month = month % 12 + 1
    day = min(d.day, _days_in_month(year, month))
    return date(year, month, day)


def _days_in_month(year: int, month: int) -> int:
    """Get number of days in a given month."""
    if month in (1, 3, 5, 7, 8, 10, 12):
        return 31
    elif month in (4, 6, 9, 11):
        return 30
    elif month == 2:
        return 29 if (year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)) else 28
    return 31

