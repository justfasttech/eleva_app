# Passo a Passo — Play Console + App Store Connect + RevenueCat

## 1. Criar o app no Google Play Console

1. Acesse [play.google.com/console](https://play.google.com/console)
2. Clique **"Criar app"**
3. Preencha:
   - **Nome:** `Eleva`
   - **Idioma padrão:** Português (Brasil)
   - **App ou jogo:** App
   - **Gratuito ou pago:** Gratuito (a assinatura é in-app, o app em si é gratuito)
4. Aceite as declarações e clique **"Criar app"**

---

## 2. Subir o AAB (App Bundle)

1. No menu lateral: **Teste → Teste interno**
2. Clique **"Criar nova versão"**
3. Faça upload do arquivo:
   ```
   build\app\outputs\bundle\release\app-release.aab
   ```
4. Preencha as notas da versão e publique

---

## 3. Configurar produto de assinatura

1. No menu lateral: **Monetizar → Produtos → Assinaturas**
2. Clique **"Criar assinatura"**
3. Preencha:
   - **ID do produto:** `eleva_premium` (esse ID é importante, anote)
   - **Nome:** `Eleva Premium`
4. Clique **"Criar"**
5. Dentro da assinatura, clique **"Adicionar plano base"**:
   - **ID do plano:** `eleva-premium-monthly`
   - **Período de cobrança:** 1 mês
   - **Preço:** defina o valor (ex: R$ 19,90)
6. Em **"Ofertas"**, adicione uma oferta com:
   - **Período de avaliação gratuita:** 30 dias
7. **Ativar** a assinatura

---

## 4. Criar Service Account (para RevenueCat validar compras)

1. Acesse [console.cloud.google.com](https://console.cloud.google.com)
2. Selecione o projeto vinculado ao seu Play Console (ou crie um)
3. Vá em **IAM e Admin → Contas de serviço**
4. Clique **"Criar conta de serviço"**:
   - **Nome:** `revenuecat`
   - Clique **Criar e continuar**
   - **Papel:** pode pular (não precisa)
   - Clique **Concluído**
5. Clique na conta criada → aba **"Chaves"**
6. **Adicionar chave → JSON** → baixe o arquivo

---

## 5. Vincular Service Account ao Play Console

1. Volte ao **Google Play Console**
2. Vá em **Configurações → Acesso à API**
3. Clique **"Vincular projeto do Google Cloud"** (se ainda não vinculou)
4. Na seção **"Contas de serviço"**, encontre a conta `revenuecat`
5. Clique **"Gerenciar permissões do Play Console"**
6. Em permissões, ative:
   - **Dados financeiros, pedidos e respostas a pesquisas de cancelamento**
   - **Gerenciar pedidos e assinaturas**
7. Clique **Convidar usuário → Enviar convite**

---

---

# PARTE B — Apple App Store Connect (iOS)

## 6. Criar o app no App Store Connect

**Pré-requisito:** Conta no Apple Developer Program ($99/ano) — [developer.apple.com](https://developer.apple.com)

1. Acesse [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Clique **"Apps"** → botão **"+"** → **"Novo App"**
3. Preencha:
   - **Plataformas:** iOS
   - **Nome:** `Eleva`
   - **Idioma principal:** Português (Brasil)
   - **Bundle ID:** selecione ou registre `com.justfasttech.eleva`
   - **SKU:** `eleva-premium-app`
4. Clique **"Criar"**

> Se o Bundle ID não aparecer na lista, registre primeiro em **Certificates, Identifiers & Profiles** → **Identifiers** → **"+"** → **App IDs** → preencha com `com.justfasttech.eleva`

---

## 7. Configurar assinatura no App Store Connect

1. No app criado, vá em **Recursos → Assinaturas**
2. Clique **"Criar grupo de assinaturas"**
   - **Nome do grupo:** `Eleva Premium`
3. Dentro do grupo, clique **"Criar assinatura"**:
   - **Nome de referência:** `Eleva Premium Mensal`
   - **ID do produto:** `eleva_premium` (mesmo ID do Play Console)
4. Configure a assinatura:
   - **Duração:** 1 mês
   - **Preço:** defina na seção de preços (ex: R$ 19,90 / $3.99)
5. Em **"Ofertas introdutórias"**, adicione:
   - **Tipo:** Avaliação gratuita
   - **Duração:** 30 dias
6. Preencha as **Informações de localização** (nome e descrição que o usuário vê)
7. Clique **"Salvar"**

---

## 8. Gerar Shared Secret (para RevenueCat)

1. No App Store Connect, vá no seu app → **Recursos → Assinaturas**
2. No canto superior direito: **"Segredo compartilhado do app"**
3. Clique **"Gerar"** e copie o código (vai usar no RevenueCat)

---

## 9. Configurar chave de API do App Store (Server-to-Server)

1. Acesse [appstoreconnect.apple.com/access/integrations/api](https://appstoreconnect.apple.com/access/integrations/api)
2. Clique **"Gerar chave de API"**
   - **Nome:** `RevenueCat`
   - **Acesso:** Admin
3. Baixe o arquivo `.p8` (só pode baixar uma vez!)
4. Anote o **Key ID** e o **Issuer ID** (aparecem na mesma tela)

---

# PARTE C — RevenueCat (unifica tudo)

## 10. Criar conta e projeto no RevenueCat

1. Acesse [app.revenuecat.com](https://app.revenuecat.com)
2. Crie uma conta (pode usar Google ou email)
3. Clique **"Create New Project"**
   - **Nome:** `Eleva`
   - Clique **Create**

---

## 11. Adicionar app Android no RevenueCat

1. No projeto Eleva, clique **"Add App"**
2. Selecione **"Google Play Store"**
3. Preencha:
   - **App name:** `Eleva Android`
   - **Package Name:** `com.justfasttech.eleva`
4. Na seção **"Service Account credentials"**:
   - Faça upload do **Service Account JSON** (o arquivo que baixou no passo 4)
5. Clique **Save**
6. **Copie a "Public API Key"** que aparece — essa é a `YOUR_GOOGLE_API_KEY` do código

---

## 12. Adicionar app iOS no RevenueCat

1. No projeto Eleva, clique **"Add App"** novamente
2. Selecione **"App Store"**
3. Preencha:
   - **App name:** `Eleva iOS`
   - **Bundle ID:** `com.justfasttech.eleva`
4. Na seção **"App-Specific Shared Secret"**:
   - Vá no App Store Connect → seu app → **Recursos → Assinaturas**
   - No canto superior: **"Segredo compartilhado do app"** → copie e cole aqui
5. Na seção **"App Store Connect API"** (para validação de compras server-side):
   - **Issuer ID:** cole o Issuer ID da sua API Key do App Store Connect
   - **Key ID:** cole o Key ID
   - **Private Key (.p8):** faça upload do arquivo `.p8`
6. Clique **Save**
7. **Copie a "Public API Key"** que aparece — essa é a `YOUR_APPLE_API_KEY` do código

---

## 13. Criar Entitlement no RevenueCat

O Entitlement representa o "direito" que o usuário ganha ao assinar.

1. No menu lateral: **Project Settings → Entitlements** (ou **Products → Entitlements**)
2. Clique **"New"**
3. Preencha:
   - **Identifier:** `premium`
   - **Display name:** `Premium`
4. Clique **Save**

---

## 14. Adicionar produtos no RevenueCat

Vincule os produtos que você criou nas lojas ao RevenueCat.

1. No menu lateral: **Products → Products**
2. Clique **"New"**

### Produto Android:
- **Store:** Google Play Store
- **Product identifier:** `eleva_premium` (mesmo ID criado no Google Play)
- Clique **Add**
- Na tela do produto, em **Entitlements** clique **Attach** → selecione `premium`

### Produto iOS:
- Clique **"New"** novamente
- **Store:** App Store
- **Product identifier:** `eleva_premium` (mesmo ID criado no App Store Connect)
- Clique **Add**
- Em **Entitlements** clique **Attach** → selecione `premium`

---

## 15. Criar Offering no RevenueCat

O Offering é o "pacote" que o app mostra na paywall.

1. No menu lateral: **Products → Offerings**
2. Já existe um offering **"Default"** — clique nele
3. Clique **"New Package"** (ou **"Add Package"**)
4. Preencha:
   - **Identifier:** selecione `$rc_monthly` (mensal)
   - **Product:** selecione `eleva_premium` (Google Play)
   - Adicione também o `eleva_premium` (App Store) para o mesmo package
5. Clique **Save**

> O offering "Default" é o que o SDK busca automaticamente com `getOfferings()`

---

## 16. Atualizar o código com as API Keys

Depois de ter as **Public API Keys**, entregue ao desenvolvedor para atualizar no arquivo:
```
lib/features/subscription/services/revenuecat_service.dart
```

Substituir:
- `YOUR_GOOGLE_API_KEY` → Public API Key da app Android (passo 11.6)
- `YOUR_APPLE_API_KEY` → Public API Key da app iOS (passo 12.7)

---

## 17. Testar no sandbox

### Android:
1. No Google Play Console → **Teste → Teste interno** → adicione seu email como testador
2. Instale o app pelo link de teste interno
3. As compras são simuladas (não cobra de verdade)

### iOS:
1. No App Store Connect → **Usuários e Acesso → Sandbox → Testers**
2. Crie um **Sandbox Tester** (email fictício + senha)
3. No iPhone, vá em **Ajustes → App Store → Conta Sandbox** → faça login com o tester
4. Abra o app e teste a compra (não cobra de verdade)

### RevenueCat Dashboard:
- Em **Customers** você vê os usuários e o status das compras em tempo real
- Em **Overview** vê métricas de receita

---

## Dados do projeto

| Item | Valor |
|------|-------|
| Package Name | `com.justfasttech.eleva` |
| Keystore | `android/app/upload-keystore.jks` |
| Keystore senha | `Eleva2026Jft` |
| Keystore alias | `upload` |
| ID assinatura | `eleva_premium` |
| ID plano | `eleva-premium-monthly` |
| Bundle ID (iOS) | `com.justfasttech.eleva` |
| SKU (iOS) | `eleva-premium-app` |
