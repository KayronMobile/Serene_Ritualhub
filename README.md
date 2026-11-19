# Serene · RitualHub

Aplicativo Flutter para **rituais estruturados** (rotina matinal, higiene do sono,
hidratação) e **responsabilidade compartilhada** por meio de desafios em grupo.

- Flutter **3.47.6** (Dart 3.13) — versão fixada em `.fvmrc`
- Arquitetura **MVVM** conforme o guia oficial
  [docs.flutter.dev/app-architecture](https://docs.flutter.dev/app-architecture/)
- Interface fiel às telas do protótipo Stitch (design system “Serene Rituals”)

---

## 1. Como rodar

O repositório contém apenas `lib/`, `test/` e `testing/`. As pastas de plataforma
são geradas pelo próprio Flutter, para usar os templates da sua versão:

```bash
fvm use 3.47.6            # ou garanta `flutter --version` = 3.47.6
flutter create . --platforms=android,ios --org app.serene --project-name ritualhub
flutter pub get
flutter test
flutter run               # usa lib/main.dart → configuração local
```

Depois do `flutter create`, aplique os ajustes de plataforma da seção 6
(notificações, biometria, câmera).

**Primeiro acesso:** digite qualquer e-mail e uma senha com 6+ caracteres. O perfil
local é criado nesse momento (ex.: `lucas@serene.com` → “Lucas”). O app abre com
dados de demonstração coerentes: 4 semanas de histórico, desafios em andamento,
amigos simulados e medalhas.

---

## 2. Arquitetura (MVVM do guia oficial)

```
┌───────────── UI layer ─────────────┐   ┌──────── Domain ────────┐   ┌──────────── Data layer ────────────┐
│ View (widgets)  ◄──►  ViewModel    │──►│ Use cases (lógica que  │──►│ Repositories (fonte da verdade)    │
│ ListenableBuilder     ChangeNotifier│   │ combina repositórios)  │   │   └─► Services (APIs/plataforma)    │
│                       + Commands    │   │ Models (imutáveis)     │   │       SharedPreferences, notificações│
└─────────────────────────────────────┘   └────────────────────────┘   │       câmera, biometria             │
                                                                      └─────────────────────────────────────┘
```

| Conceito do guia | Onde está |
|---|---|
| **View** — só exibe estado e encaminha eventos | `lib/ui/<feature>/widgets/*_screen.dart` |
| **ViewModel** — estado da tela + ações via `Command` | `lib/ui/<feature>/view_models/*_viewmodel.dart` |
| **Command** (`Command0`/`Command1`: running/completed/error) | `lib/utils/command.dart` |
| **Result** (`Ok`/`Error`, sem exceções entre camadas) | `lib/utils/result.dart` |
| **Repository** — abstrato + implementação local | `lib/data/repositories/<tipo>/` |
| **Service** — encapsula APIs externas | `lib/data/services/` |
| **Use case** (camada de domínio opcional) | `lib/domain/use_cases/` |
| **Models** de domínio | `lib/domain/models/` |
| **Injeção de dependências** com `provider` | `lib/config/dependencies.dart` |
| **Roteamento** declarativo com `go_router` | `lib/routing/` |
| Ambientes (`main_development.dart`) | `lib/main*.dart` |
| Testes espelhando `lib/` + `testing/` com fakes | `test/`, `testing/` |

Decisões importantes:

- **Repositórios estendem `ChangeNotifier`** (como o `AuthRepository` do app Compass).
  Assim, as telas mantidas vivas pelo `StatefulShellRoute` (Hoje, Progresso…) se
  atualizam quando outra tela muda os dados, por exemplo quando o player conclui
  um passo de hidratação.
- **Repositórios não conhecem uns aos outros.** Toda regra que cruza dados fica em
  *use cases*: relatório semanal, medalhas, plano de lembretes e conclusão de passo
  (que alimenta rastreadores e faz check-in automático).
- **`ViewModelBuilder`** (`lib/ui/core/view_model.dart`) cria cada ViewModel uma única
  vez por tela e o descarta ao sair. Isso evita duplicação quando o `go_router`
  reconstrói páginas.
- **Trocar o backend** exige só uma nova lista de providers com, por exemplo,
  `RitualRepositoryRemote`. Views e ViewModels não mudam.

```
lib/
├── config/dependencies.dart
├── data/
│   ├── repositories/{auth,ritual,health,challenge,achievement,reminder}/
│   │   ├── <tipo>_repository.dart          # contrato
│   │   └── <tipo>_repository_local.dart    # implementação local
│   └── services/                            # storage, notificações, biometria, fotos, seed
├── domain/
│   ├── models/                              # Ritual, RitualStep, DailyHealthLog, Challenge…
│   └── use_cases/                           # relatório, medalhas, lembretes, conclusão de passo
├── routing/{router.dart, routes.dart}
├── ui/
│   ├── core/{themes, ui, view_model.dart}   # design system + widgets compartilhados
│   ├── auth/  home/  rituals/  ritual_builder/  ritual_player/
│   └── community/  reports/  reminders/  profile/
└── utils/{command.dart, result.dart, dates.dart}
```

---

## 3. Requisitos funcionais → implementação

| Requisito | Implementação |
|---|---|
| **Construtor de Rituais Sequenciais** | `ritual_builder/`: nome, período (Manhã/Tarde/Noite), blocos encadeados com **arrastar para ordenar** (`SliverReorderableList`), editor de bloco (tipo, temporizador, meta de ml, instrução, dica, som ambiente), sugestões rápidas, dias ativos, horário, lembrete suave, Modo Zen e vínculo com desafio. |
| **Player guiado por temporizador** | `ritual_player/`: anel de progresso, passo atual, “a seguir”, +1 minuto, pausar, pular, lista de passos, vibração ao fim do tempo, Modo Zen (tela cheia) e tela de celebração com medalhas novas. Retoma do primeiro passo pendente do dia. |
| **Rastreadores de saúde na tela inicial** | `home/`: widgets de **água (ml)** com botão rápido +250 ml e atalhos, **sono** (duração e eficácia), **leitura** e **movimento** em minutos. Passos do ritual alimentam os rastreadores automaticamente (hidratação → ml; movimento → atividade; leitura → leitura). |
| **Desafios coletivos e grupos de apoio** | `community/`: abas Ativos / Meus Grupos / Descobrir, criação de desafio temporário com convite de amigos (modelos “21 Dias Sem Açúcar”, “30 Dias de Leitura”…), **feed de check-ins fotográficos** (câmera/galeria, selo, reações, comentários), **mural de incentivo** (“Lembrança afetuosa” para quem ainda não registrou) e **placar de consistência** (taxa do grupo, sequência, % e medalhas de posição). |
| **Relatórios semanais de consistência** | `reports/` + `WeeklyReportUseCase`: barras de aderência por dia, consistência geral e variação vs. semana anterior, **detecção do dia da semana de maior falha** (últimas 4 semanas), média de hidratação (gráfico de linha + meta), média e regularidade do sono, minutos guiados e sequência atual. |
| **Lembretes inteligentes** | `PlanRemindersUseCase` + `LocalNotificationService`: início de cada ritual (com antecedência, só nos dias ativos), **intervalos de água adaptativos** (mostram quanto falta, silenciam ao bater a meta e são replanejados a cada registro) e **“desligar telas”** à noite, antecipado 30 min no dia vulnerável com 1 toque a partir do insight do relatório. Tela de ajustes em `reminders/`. |
| **Conquistas e medalhas** | `EvaluateAchievementsUseCase`: 8 medalhas **individuais** (Madrugador Sereno, Guardião da Hidratação, Mestre do Foco, Primeira Semente, Leitor Constante, Descanso Profundo) e **de grupo** (Força Compartilhada, Tribo em Sintonia), com progresso, data de desbloqueio e selo “Nova!”. |

Telas do protótipo → arquivos: `login_entrar_no_serene` → `auth/`,
`hoje_dashboard_de_rituais` → `home/`, `construtor_de_rituais` → `ritual_builder/`,
`player_de_ritual_guiado` → `ritual_player/`, `comunidade_desafios` → `community/`,
`relat_rios_conquistas` → `reports/`. As telas extras (lista de Rituais, Lembretes,
Perfil & Metas e Cadastro) completam os fluxos.

---

## 4. Modo local, sem backend

Os requisitos não especificam um servidor, então a camada de dados roda **inteiramente
no aparelho** (`*_repository_local.dart` + `SharedPreferences`):

- **Login/cadastro:** perfil único por aparelho. A senha é guardada só como hash
  simples, adequado para demonstração e não para produção. A biometria fica disponível
  depois de um login com “Lembrar de mim”. Login com Apple/Google exige backend e
  mostra um aviso.
- **Amigos e atividade da tribo:** são **simulados de forma determinística** pelo
  `ChallengeRepositoryLocal`, com check-ins diários por amigo, para que placar, feed
  e “cuidado compartilhado” funcionem. As suas ações (check-ins, reações,
  comentários, lembranças) são persistidas.
- **Som ambiente:** o player tem o controle de som (tocar/pausar), mas o projeto não
  inclui arquivos de áudio. Para tocar de verdade, adicione os arquivos em `assets/` e
  um `AudioService` (ex.: `just_audio`) na camada de serviços.

Para produção, crie `lib/main_staging.dart` e `providersRemote`, com repositórios
que falem com a sua API ou com o Firebase (Auth, Firestore em tempo real, Storage
para fotos e FCM). Os contratos em `data/repositories/*/*_repository.dart` já estão
prontos para isso.

---

## 5. Testes

```bash
flutter test
```

- `test/utils/command_test.dart`: estados do `Command`.
- `test/domain/consistency_calculator_test.dart`: sequência e placar.
- `test/domain/plan_reminders_use_case_test.dart`: lembretes adaptativos, dia vulnerável e ids únicos.
- `test/domain/complete_ritual_step_use_case_test.dart`: rastreadores e check-in automático.
- `test/domain/weekly_report_use_case_test.dart`: detecção da sexta-feira e médias.
- `test/ui/ritual_player_viewmodel_test.dart`, `test/ui/home_viewmodel_test.dart`: ViewModels.
- `test/ui/login_screen_test.dart`: widget de login (validação e autenticação).

`testing/fakes/` traz o `FakeEnvironment`, que monta toda a camada de dados sobre um
`SharedPreferences` em memória com relógio fixo, e fakes de notificação, biometria e
câmera.

---

## 6. Ajustes de plataforma (depois do `flutter create`)

### Android

`android/app/build.gradle.kts`, exigido por `flutter_local_notifications`:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>              <!-- google_fonts -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>

<application ...>
    <receiver android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
    <receiver android:exported="false"
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED"/>
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
        </intent-filter>
    </receiver>
</application>
```

`MainActivity.kt`: para o `local_auth`, troque `FlutterActivity` por `FlutterFragmentActivity`:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity : FlutterFragmentActivity()
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Para registrar check-ins fotográficos nos desafios.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Para escolher fotos dos seus check-ins.</string>
<key>NSFaceIDUsageDescription</key>
<string>Para entrar no Serene com segurança.</string>
```

`AppDelegate.swift`, para exibir notificações com o app aberto:

```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```

---

## 7. Notas de versão

- O Flutter 3.47 ainda inclui `package:flutter/material.dart`, e o app o usa. A
  migração opcional para os pacotes `material_ui`/`cupertino_ui` pode ser feita
  depois com `dart fix --apply --code=migrate_design_widgets`. Por isso o `go_router`
  está fixado em `^17.2.0`: a série 18.x já migrou para `material_ui`.
- `flutter_local_notifications` 20+ usa parâmetros nomeados (`zonedSchedule(id: …)`).
  `local_auth` 3.x usa `authenticate(localizedReason: …, persistAcrossBackgrounding: …)`.
- Os horários são agendados convertendo o horário local para UTC, sem depender de
  `flutter_timezone`. O app replaneja os lembretes a cada abertura e a cada mudança
  relevante (ritual salvo, água registrada, ajuste de lembretes).
- A tipografia **Plus Jakarta Sans** vem do `google_fonts`. Para uso offline, coloque
  os `.ttf` em `assets/google_fonts/` e declare-os no `pubspec.yaml`.
