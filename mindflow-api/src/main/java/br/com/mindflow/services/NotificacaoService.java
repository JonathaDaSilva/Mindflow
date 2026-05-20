package br.com.mindflow.services;

import br.com.mindflow.repositories.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificacaoService {

    private final UsuarioRepository usuarioRepo;

    public void notificar(UUID usuarioId, String titulo, String corpo) {
        usuarioRepo.findById(usuarioId).ifPresentOrElse(usuario -> {
            String fcmToken = usuario.getFcmToken();

            if (fcmToken == null || fcmToken.isBlank()) {
                log.warn("[NOTIFICACAO] Usuário {} sem FCM token registrado — notificação ignorada",
                        usuarioId);
                return;
            }

            // Por enquanto loga — Sprint 4 integra FCM real
            log.info("[NOTIFICACAO] → {} | titulo: '{}' | corpo: '{}'",
                    usuario.getNome(), titulo, corpo);

            // Sprint 4: descomentar e implementar chamada FCM
            // enviarPush(fcmToken, titulo, corpo);

        }, () -> log.warn("[NOTIFICACAO] Usuário {} não encontrado", usuarioId));
    }

    // Sprint 4: implementar chamada HTTP para FCM
    // private void enviarPush(String token, String titulo, String corpo) {
    //     RestClient.create()
    //         .post()
    //         .uri("https://fcm.googleapis.com/v1/projects/{projectId}/messages:send")
    //         .header("Authorization", "Bearer " + getAccessToken())
    //         .body(montarPayload(token, titulo, corpo))
    //         .retrieve()
    //         .toBodilessEntity();
    // }
}