# Changelog

## 1.0.0
- Redesign the API to accept a Paystack access code supplied by your backend.
- Removed client-side transaction initialization and the `http` dependency.
- Added resilient WebView handling so the checkout survives bank-app/USSD switches.
- Added optional `PaystackCheckoutOptions` for customizing the WebView screen.
- Introduced `url_launcher` integration to open external banking apps safely.

## 0.0.4
- Initial release with Paystack Checkout integration.
- Supports payment channels, custom metadata, and WebView-based UI.
- Bug fixed
