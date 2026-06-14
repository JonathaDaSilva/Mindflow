// Exporta a implementação nativa em Android/iOS/desktop,
// e o stub no-op quando rodando no Chrome (dart.library.html disponível na web).
export 'notificacao_local_service_native.dart'
    if (dart.library.html) 'notificacao_local_service_web.dart';
