# 📱 Guia de Customização do Website

## 🔧 Configurações Importantes

### 1. **Número de WhatsApp**
Locais a atualizar:
- `web/components/sections/header.tsx` (linha 11)
- `web/components/sections/footer.tsx` (linha 4)
- `web/components/sections/contact.tsx` (linha 2)

**Formato:** `5511987654321` (código país + DDD + número)

**Exemplo:**
```typescript
const whatsappNumber = '5511987654321'; // Seu número aqui
```

Para testar: https://wa.me/5511987654321

### 2. **Email de Contato**
Locais a atualizar:
- `web/components/sections/header.tsx` (ainda não está hardcoded)
- `web/components/sections/footer.tsx` (linha 29)
- `web/components/sections/contact.tsx` (linha 4)

**Exemplo:**
```typescript
const emailAddress = 'suporte@amortizadorpro.com';
```

---

## 📄 Seções do Website

### Header (`header.tsx`)
- **Função:** Navegação principal
- **Features:**
  - Menu responsivo (hamburger no mobile)
  - Links rápidos
  - Botão WhatsApp
  - Botão Download App
- **Customizável:** Cores, links, ordem do menu

### Support (`support.tsx`)
- **Função:** Centro de suporte com 6 tópicos principais
- **Cards:**
  1. Como Começar
  2. Economia com Amortização
  3. App Mobile
  4. Segurança
  5. FAQ
  6. Reportar Bug
- **Próximo:** Criar páginas `/docs/*` para cada tópico

### Contact (`contact.tsx`)
- **Função:** Seção de contato
- **Métodos:**
  - WhatsApp (chat direto)
  - Email (formulário)
- **Customizável:** Mensagens, horários, números

### Footer (`footer.tsx`)
- **Função:** Rodapé com navegação secundária
- **Seções:**
  - Brand + sociais
  - Produto
  - Ajuda
  - Legal
- **Customizável:** Links, copyright, descrição

---

## 🚀 Deploy

```bash
cd web
npm run build
npm run start
```

## 📱 Páginas Faltantes (TODO)

- `/docs/tutorial` - Tutorial completo
- `/docs/calculadora` - Como funciona a calculadora
- `/docs/sac-price` - SAC vs PRICE
- `/docs/privacidade` - Privacidade e Segurança
- `/termos` - Termos de Uso
- `/privacidade` - Política de Privacidade
- `/cookies` - Política de Cookies
- `/acessibilidade` - Acessibilidade

---

## 🎨 Design System

**Cores Principais:**
- `brand-navy`: `#001F3F` (azul escuro)
- `brand-navy-dark`: `#001428` (azul mais escuro)
- `brand-navy-light`: `#a8b5c1` (azul claro)
- `green-500`: `#10b981` (WhatsApp)
- `blue-500`: `#3b82f6` (Email)

**Espaçamento:**
- `section-padding`: Padding padrão para seções
- `section-container`: Container com max-width

---

## 📧 Formulário de Contato (Futuro)

Opções de implementação:
1. **EmailJS** - Envio de email sem backend
2. **Nodemailer** - Backend Node.js
3. **SendGrid** - Serviço de email
4. **Supabase** - Integração com backend existente

---

## ✅ Checklist de Launch

- [ ] Atualizar número WhatsApp em 3 arquivos
- [ ] Atualizar email de contato
- [ ] Criar páginas de documentação
- [ ] Testar links de navegação
- [ ] Testar responsividade mobile
- [ ] Testar WhatsApp (abre chat)
- [ ] Testar Email (abre formulário)
- [ ] Deploy em produção

