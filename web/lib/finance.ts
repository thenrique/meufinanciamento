export interface FinanceInput {
  balance: number;
  annualRate: number;
  months: number;
  extraMonthly: number;
  system: 'SAC' | 'PRICE';
}

export interface MonthEntry {
  month: number;
  balance: number;
  principal: number;
  interest: number;
  extra: number;
  payment: number;
}

export interface FinanceResult {
  monthsSaved: number;
  interestSaved: number;
  payoffDate: Date;
  totalInterestBase: number;
  totalInterestExtra: number;
  schedule: MonthEntry[];
}

function monthlyRate(annualRate: number): number {
  return annualRate / 100 / 12;
}

export function calculateSAC(
  balance: number,
  annualRate: number,
  months: number,
  extraMonthly: number,
): FinanceResult {
  const rate = monthlyRate(annualRate);
  const basePrincipal = balance / months;

  // Calculate baseline total interest (no extra payment)
  let baseInterest = 0;
  let bal = balance;
  for (let i = 0; i < months; i++) {
    baseInterest += bal * rate;
    bal -= basePrincipal;
    if (bal < 0) bal = 0;
  }

  // Calculate with extra payment
  const schedule: MonthEntry[] = [];
  let currentBalance = balance;
  let totalInterestExtra = 0;
  let monthCount = 0;

  while (currentBalance > 0.01 && monthCount < months) {
    const interest = currentBalance * rate;
    const principal = Math.min(basePrincipal, currentBalance);
    const extra = Math.min(extraMonthly, Math.max(0, currentBalance - principal));
    const payment = principal + interest + extra;

    totalInterestExtra += interest;
    schedule.push({
      month: monthCount + 1,
      balance: currentBalance,
      principal,
      interest,
      extra,
      payment,
    });

    currentBalance -= principal + extra;
    if (currentBalance < 0.01) currentBalance = 0;
    monthCount++;
  }

  const monthsSaved = months - monthCount;
  const interestSaved = baseInterest - totalInterestExtra;

  const payoffDate = new Date();
  payoffDate.setMonth(payoffDate.getMonth() + monthCount);

  return {
    monthsSaved,
    interestSaved,
    payoffDate,
    totalInterestBase: baseInterest,
    totalInterestExtra,
    schedule,
  };
}

export function calculatePRICE(
  balance: number,
  annualRate: number,
  months: number,
  extraMonthly: number,
): FinanceResult {
  const rate = monthlyRate(annualRate);

  // PRICE fixed payment formula: PMT = PV * rate / (1 - (1+rate)^-n)
  const fixedPayment =
    rate === 0
      ? balance / months
      : (balance * rate) / (1 - Math.pow(1 + rate, -months));

  // Baseline total interest
  let bal = balance;
  let baseInterest = 0;
  for (let i = 0; i < months; i++) {
    const interest = bal * rate;
    const principal = fixedPayment - interest;
    baseInterest += interest;
    bal -= principal;
    if (bal < 0.01) break;
  }

  // With extra payment
  const schedule: MonthEntry[] = [];
  let currentBalance = balance;
  let totalInterestExtra = 0;
  let monthCount = 0;

  while (currentBalance > 0.01 && monthCount < months) {
    const interest = currentBalance * rate;
    const principal = Math.min(fixedPayment - interest, currentBalance);
    const extra = Math.min(extraMonthly, Math.max(0, currentBalance - principal));
    const payment = principal + interest + extra;

    totalInterestExtra += interest;
    schedule.push({
      month: monthCount + 1,
      balance: currentBalance,
      principal,
      interest,
      extra,
      payment,
    });

    currentBalance -= principal + extra;
    if (currentBalance < 0.01) currentBalance = 0;
    monthCount++;
  }

  const monthsSaved = months - monthCount;
  const interestSaved = baseInterest - totalInterestExtra;

  const payoffDate = new Date();
  payoffDate.setMonth(payoffDate.getMonth() + monthCount);

  return {
    monthsSaved,
    interestSaved,
    payoffDate,
    totalInterestBase: baseInterest,
    totalInterestExtra,
    schedule,
  };
}

export function calculate(input: FinanceInput): FinanceResult {
  if (input.system === 'SAC') {
    return calculateSAC(input.balance, input.annualRate, input.months, input.extraMonthly);
  }
  return calculatePRICE(input.balance, input.annualRate, input.months, input.extraMonthly);
}
