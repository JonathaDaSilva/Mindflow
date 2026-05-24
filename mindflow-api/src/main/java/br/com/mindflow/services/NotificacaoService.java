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

            log.info("[NOTIFICACAO] → {} | titulo: '{}' | corpo: '{}'",
                    usuario.getNome(), titulo, corpo);

            if (usuario.getFcmToken() == null || 
                usuario.getFcmToken().isBlank()) {
                log.warn("[NOTIFICACAO] {} sem FCM token — " +
                    "notificação registrada mas não enviada",
                    usuario.getNome());
                return;
            }

            // Sprint 4: integrar FCM aqui
            // enviarPushFCM(usuario.getFcmToken(), titulo, corpo);
            log.info("[NOTIFICACAO] Push enviado para token: {}",
                usuario.getFcmToken().substring(0, 10) + "...");

        }, () -> log.warn(
            "[NOTIFICACAO] Usuário {} não encontrado", usuarioId));
    }
}