# Nep - Modern Banking App

Una aplicación bancaria moderna construida con SwiftUI que se conecta a la API de Nessie para proporcionar servicios bancarios digitales.

## Características

- 🏠 **Dashboard Principal**: Vista completa de balances, cuentas y transacciones
- 💳 **Gestión de Tarjetas**: Visualización y gestión de tarjetas de débito
- 💰 **Múltiples Monedas**: Soporte para USD, EUR y AUD
- 📱 **Diseño Moderno**: Interfaz inspirada en las mejores apps bancarias
- 🔒 **Seguridad**: Integración con API bancaria real

## Configuración

### 1. API Key de Nessie

1. Ve a [Capital One Developer](https://developer.capitalone.com/)
2. Regístrate para obtener una API key gratuita
3. Abre `Nep/Utils/Config.swift`
4. Reemplaza `YOUR_NESSIE_API_KEY_HERE` con tu API key real

```swift
struct Config {
    static let nessieAPIKey = "tu_api_key_aqui"
    static let nessieBaseURL = "https://api.reimaginebanking.com"
    // ...
}
```

### 2. Estructura del Proyecto

```
Nep/
├── Models/           # Modelos de datos
│   ├── User.swift
│   ├── Transaction.swift
│   └── CreditOffer.swift
├── Services/         # Servicios de API
│   ├── NessieAPI.swift
│   └── QuantumAPI.swift
├── Views/           # Vistas de la interfaz
│   ├── WelcomeView.swift
│   ├── DashboardView.swift
│   ├── CardDetailsView.swift
│   └── MainView.swift
├── ViewModels/      # Lógica de negocio
│   └── BankingViewModel.swift
├── Utils/           # Utilidades
│   ├── Config.swift
│   ├── Formatters.swift
│   └── MockData.swift
└── Extensions/      # Extensiones
    └── Color+Theme.swift
```

## Uso

### Modo Desarrollo (Mock Data)
Por defecto, la app usa datos mock para desarrollo. Los datos se cargan automáticamente al iniciar.

### Modo Producción (API Real)
Para usar la API real de Nessie:

1. Configura tu API key en `Config.swift`
2. En `BankingViewModel.swift`, cambia `loadMockData()` por `loadUserData()`
3. La app se conectará automáticamente a la API de Nessie

## Pantallas

### 1. Pantalla de Bienvenida
- Logo animado con asterisco
- Mensaje de bienvenida
- Botones de registro y login

### 2. Dashboard Principal
- Balances en múltiples monedas
- Selector de cuentas
- Botones de acción (Add, Send, Convert, More)
- Lista de transacciones recientes

### 3. Detalles de Tarjeta
- Visualización de tarjeta digital
- Información de la tarjeta (número, CVC, fecha de vencimiento)
- Balance total

### 4. Navegación
- Tab bar con 5 secciones
- Navegación fluida entre pantallas

## API Endpoints Utilizados

- `GET /customers` - Obtener clientes
- `GET /customers/{id}/accounts` - Obtener cuentas del cliente
- `GET /accounts/{id}/transactions` - Obtener transacciones de la cuenta
- `GET /customers/{id}/cards` - Obtener tarjetas del cliente
- `POST /customers` - Crear nuevo cliente
- `POST /accounts` - Crear nueva cuenta
- `POST /transactions` - Crear nueva transacción

## Colores y Tema

La app usa un sistema de colores personalizado definido en `Color+Theme.swift`:

- **Nep Blue**: Color principal (#0066CC)
- **Nep Light Blue**: Color secundario (#3399FF)
- **Nep Dark Blue**: Color oscuro (#003399)
- **Nep Background**: Fondo claro (#F2F7FF)
- **Nep Dark Background**: Fondo oscuro (#1A1A26)

## Desarrollo

### Requisitos
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Instalación
1. Clona el repositorio
2. Abre `Nep.xcodeproj` en Xcode
3. Configura tu API key de Nessie
4. Ejecuta la app en el simulador o dispositivo

### Estructura de Datos

#### User
```swift
struct User {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let address: Address?
    let accounts: [Account]?
    let cards: [Card]?
}
```

#### Transaction
```swift
struct Transaction {
    let id: String
    let type: String
    let transactionDate: String
    let status: String
    let payer: Payer
    let payee: Payee
    let amount: Double
    let medium: String
    let description: String?
}
```

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## Contacto

Para preguntas o soporte, contacta al equipo de desarrollo.
