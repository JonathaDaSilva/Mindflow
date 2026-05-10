package br.com.mindflow.security;

import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.util.Base64;
import java.util.Date;

@Service
public class JwtService {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private Long expiration;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(
            Decoders.BASE64.decode(
                Base64.getEncoder().encodeToString(secret.getBytes())
            )
        );
    }

    public String gerarToken(UserDetails usuario) {
        return Jwts.builder()
            .subject(usuario.getUsername())  
            .claim("perfil", usuario          
                .getAuthorities().iterator()
                .next().getAuthority())
            .issuedAt(new Date())
            .expiration(new Date(
                System.currentTimeMillis() + expiration))
            .signWith(getSigningKey())
            .compact();
    }

    public String extrairEmail(String token) {
        return Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload()
            .getSubject();
    }

    public boolean tokenValido(String token, UserDetails usuario) {
        try {
            String email = extrairEmail(token);
            return email.equals(usuario.getUsername())
                && !tokenExpirado(token);
        } catch (JwtException e) {
            return false;  
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