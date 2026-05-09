package br.com.mindflow.security;

import java.util.Base64;
import java.util.Date;

import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.JwtException;
import javax.crypto.SecretKey;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private Long expiration;

    // Gera a chave de assinatura a partir do secret do yml
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(
            Decoders.BASE64.decode(
                Base64.getEncoder().encodeToString(secret.getBytes())
            )
        );
    }

    // Gera o token com o email do usuário como subject
    public String gerarToken(UserDetails usuario) {
        return Jwts.builder()
            .subject(usuario.getUsername())   // email
            .claim("perfil", usuario           // perfil no payload
                .getAuthorities().iterator()
                .next().getAuthority())
            .issuedAt(new Date())
            .expiration(new Date(
                System.currentTimeMillis() + expiration))
            .signWith(getSigningKey())
            .compact();
    }

    // Extrai o email (subject) do token
    public String extrairEmail(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload()
            .getSubject();
    }

    // Valida: assinatura correta + não expirado + email bate
    public boolean tokenValido(String token, UserDetails usuario) {
        try {
            String email = extrairEmail(token);
            return email.equals(usuario.getUsername())
                && !tokenExpirado(token);
        } catch (JwtException e) {
            return false;  // token inválido ou adulterado
        }
    }

    private boolean tokenExpirado(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey()).build()
            .parseSignedClaims(token)
            .getPayload().getExpiration()
            .before(new Date());
    }
}