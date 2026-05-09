package br.com.mindflow.security;

import org.springframework.stereotype.Component;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;
import lombok.RequiredArgsConstructor;


@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain chain)
            throws ServletException, IOException {

        // 1. Pega o header Authorization
        String authHeader = request.getHeader("Authorization");

        // 2. Se não tem token, deixa passar (rota pública vai funcionar)
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }

        // 3. Extrai o token (remove "Bearer ")
        String token = authHeader.substring(7);

        // 4. Extrai o email do token
        String email = jwtService.extrairEmail(token);

        // 5. Se tem email e nenhum usuário autenticado ainda
        if (email != null &&
            SecurityContextHolder.getContext()
                .getAuthentication() == null) {

            // 6. Busca o usuário no banco pelo email
            UserDetails usuario =
                userDetailsService.loadUserByUsername(email);

            // 7. Valida o token
            if (jwtService.tokenValido(token, usuario)) {

                // 8. Registra no contexto — Spring sabe quem está logado
                var auth = new UsernamePasswordAuthenticationToken(
                    usuario, null, usuario.getAuthorities()
                );
                auth.setDetails(new
                    WebAuthenticationDetailsSource()
                        .buildDetails(request));
                SecurityContextHolder.getContext()
                    .setAuthentication(auth);
            }
        }
        chain.doFilter(request, response);
    }
}
