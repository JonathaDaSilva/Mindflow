# MindFlow API — Documentação dos Endpoints

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Curso:** Engenharia de Software — PUC Minas | 1º Semestre 2026  
**Sprint:** 1 — Backend REST + Autenticação JWT  
**Base URL:** `http://localhost:8080`  
**Autenticação:** Bearer Token JWT — obtido via `/auth/login` ou `/auth/registrar`

---

## Como executar

1. Suba a infraestrutura: `podman compose up -d`
2. Rode o backend: `mvn spring-boot:run`
3. Importe o arquivo `mindflow.postman_collection.json` no Postman
4. Execute **Registrar Paciente** ou **Registrar Psicólogo** — o token é salvo automaticamente na variável `{{token}}`
5. Todas as demais requisições usam `{{token}}` automaticamente

---

## Variáveis da coleção

| Variável | Descrição | Preenchida por |
|---|---|---|
| `baseUrl` | URL base da API | Manual (`http://localhost:8080`) |
| `token` | JWT do usuário autenticado | Script do Registrar/Login |
| `pacienteUsuarioId` | UUID do paciente registrado | Script do Registrar Paciente |
| `psicologoUsuarioId` | UUID do psicólogo registrado | Script do Registrar Psicólogo |

---

## 1. Auth

### POST /auth/registrar — Registrar Paciente

Cria um novo usuário com perfil PACIENTE e seu perfil de dados pessoais em uma única transação.

**Headers**
```
Content-Type: application/json
```

**Request Body**
```json
{
  "nome": "João Silva",
  "email": "joao@email.com",
  "senha": "123456",
  "perfil": "PACIENTE",
  "dadosPaciente": {
    "telefone": "(31) 99999-0000",
    "dataNascimento": "1995-06-15",
    "formaPagamentoPref": "PIX",
    "observacoesSaude": "Ansiedade leve"
  }
}
```

**Response 201 — Created**
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "userId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "nome": "João Silva",
  "email": "joao@email.com",
  "perfil": "PACIENTE"
}
```

**Testes automatizados**
- Status 201
- `token` retornado é string
- `perfil` igual a `"PACIENTE"`

---

### POST /auth/registrar — Registrar Psicólogo

Cria um novo usuário com perfil PSICOLOGO e seu perfil profissional em uma única transação.

**Headers**
```
Content-Type: application/json
```

**Request Body**
```json
{
  "nome": "Dra. Ana Lima",
  "email": "ana@email.com",
  "senha": "123456",
  "perfil": "PSICOLOGO",
  "dadosPsicologo": {
    "crp": "06/12345",
    "especialidade": "Ansiedade e Depressão",
    "bio": "10 anos de experiência em saúde mental",
    "regimeTrabalho": "HIBRIDO",
    "duracaoSessaoMin": 50,
    "valorSessao": 180.00,
    "aceitaEmergencia": true,
    "endereco": {
      "logradouro": "Rua das Flores",
      "numero": "123",
      "bairro": "Centro",
      "cidade": "Belo Horizonte",
      "estado": "MG",
      "cep": "30130-110"
    }
  }
}
```

**Response 201 — Created**
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "userId": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nome": "Dra. Ana Lima",
  "email": "ana@email.com",
  "perfil": "PSICOLOGO"
}
```

**Testes automatizados**
- Status 201
- `token` retornado é string
- `perfil` igual a `"PSICOLOGO"`

---

### POST /auth/login

Autentica um usuário existente e retorna um novo token JWT.

**Headers**
```
Content-Type: application/json
```

**Request Body**
```json
{
  "email": "ana@email.com",
  "senha": "123456"
}
```

**Response 200 — OK**
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9...",
  "userId": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nome": "Dra. Ana Lima",
  "email": "ana@email.com",
  "perfil": "PSICOLOGO"
}
```

**Testes automatizados**
- Status 200
- `token` retornado é string

---

### [ERRO] POST /auth/login — Senha incorreta

**Request Body**
```json
{
  "email": "ana@email.com",
  "senha": "senhaerrada"
}
```

**Response 401 — Unauthorized**
```json
{
  "error": "Email ou senha incorretos"
}
```

**Testes automatizados**
- Status 401
- `error` contém `"incorretos"`

---

### [ERRO] POST /auth/registrar — E-mail duplicado

**Request Body**
```json
{
  "nome": "Outro João",
  "email": "joao@email.com",
  "senha": "123456",
  "perfil": "PACIENTE",
  "dadosPaciente": {
    "telefone": "(31) 88888-0000"
  }
}
```

**Response 409 — Conflict**
```json
{
  "error": "Email já cadastrado: joao@email.com"
}
```

**Testes automatizados**
- Status 409

---

### [ERRO] POST /auth/registrar — Sem dadosPaciente

**Request Body**
```json
{
  "nome": "Maria",
  "email": "maria@email.com",
  "senha": "123456",
  "perfil": "PACIENTE"
}
```

**Response 400 — Bad Request**
```json
{
  "error": "Campo obrigatório ausente para o perfil: dadosPaciente"
}
```

**Testes automatizados**
- Status 400

---

## 2. Usuário

> Todos os endpoints desta seção exigem: `Authorization: Bearer {{token}}`

---

### GET /usuarios/me

Retorna os dados do usuário autenticado.

**Headers**
```
Authorization: Bearer {{token}}
```

**Response 200 — OK**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "nome": "João Silva",
  "email": "joao@email.com",
  "perfil": "PACIENTE",
  "criadoEm": "2026-05-10T22:30:00"
}
```

**Testes automatizados**
- Status 200
- `id` é string
- `email` é string

---

### PUT /usuarios/me

Atualiza o nome do usuário autenticado.

**Headers**
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Request Body**
```json
{
  "nome": "Ana Lima Atualizada"
}
```

**Response 200 — OK**
```json
{
  "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nome": "Ana Lima Atualizada",
  "email": "ana@email.com",
  "perfil": "PSICOLOGO",
  "criadoEm": "2026-05-10T22:31:00"
}
```

**Testes automatizados**
- Status 200
- `nome` igual a `"Ana Lima Atualizada"`

---

### [ERRO] GET /usuarios/me — Sem token

**Headers**
```
(sem Authorization)
```

**Response 401 ou 403**

**Testes automatizados**
- Status 401 ou 403

---

## 3. Paciente

> Endpoints exigem token de usuário com perfil `PACIENTE`

---

### GET /pacientes/perfil

Retorna o perfil completo do paciente autenticado, incluindo `observacoesSaude`.

**Headers**
```
Authorization: Bearer {{token}}
```

**Response 200 — OK**
```json
{
  "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "nome": "João Silva",
  "email": "joao@email.com",
  "telefone": "(31) 99999-0000",
  "dataNascimento": "1995-06-15",
  "formaPagamentoPref": "PIX",
  "observacoesSaude": "Ansiedade leve",
  "criadoEm": "2026-05-10T22:30:00"
}
```

**Testes automatizados**
- Status 200
- Propriedade `observacoesSaude` presente

---

### PUT /pacientes/perfil

Atualiza os dados do perfil do paciente autenticado.

**Headers**
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Request Body**
```json
{
  "telefone": "(31) 98888-1111",
  "dataNascimento": "1995-06-15",
  "formaPagamentoPref": "CARTAO_CREDITO",
  "observacoesSaude": "Ansiedade moderada"
}
```

**Response 200 — OK**
```json
{
  "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "nome": "João Silva",
  "email": "joao@email.com",
  "telefone": "(31) 98888-1111",
  "dataNascimento": "1995-06-15",
  "formaPagamentoPref": "CARTAO_CREDITO",
  "observacoesSaude": "Ansiedade moderada",
  "criadoEm": "2026-05-10T22:30:00"
}
```

**Testes automatizados**
- Status 200
- `telefone` igual a `"(31) 98888-1111"`

---

### DELETE /pacientes/delete/{usuarioId}

Remove o perfil do paciente. O usuário é mantido para preservar histórico.

**Headers**
```
Authorization: Bearer {{token}}
```

**Response 204 — No Content**

---

## 4. Psicólogo

> Endpoints de perfil exigem token com perfil `PSICOLOGO`

---

### GET /psicologos

Lista todos os psicólogos ativos. Disponível para qualquer usuário autenticado.

**Headers**
```
Authorization: Bearer {{token}}
```

**Response 200 — OK**
```json
[
  {
    "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
    "nome": "Dra. Ana Lima",
    "crp": "06/12345",
    "especialidade": "Ansiedade e Depressão",
    "bio": "10 anos de experiência em saúde mental",
    "regimeTrabalho": "HIBRIDO",
    "duracaoSessaoMin": 50,
    "valorSessao": 180.00,
    "aceitaEmergencia": true,
    "endereco": {
      "logradouro": "Rua das Flores",
      "numero": "123",
      "bairro": "Centro",
      "cidade": "Belo Horizonte",
      "estado": "MG",
      "cep": "30130-110"
    }
  }
]
```

**Testes automatizados**
- Status 200
- Retorna array

---

### GET /psicologos/perfil

Retorna o perfil profissional do psicólogo autenticado.

**Headers**
```
Authorization: Bearer {{token}}
```

**Response 200 — OK**
```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "nome": "Dra. Ana Lima",
  "crp": "06/12345",
  "especialidade": "Ansiedade e Depressão",
  "bio": "10 anos de experiência em saúde mental",
  "regimeTrabalho": "HIBRIDO",
  "duracaoSessaoMin": 50,
  "valorSessao": 180.00,
  "aceitaEmergencia": true,
  "endereco": {
    "logradouro": "Rua das Flores",
    "numero": "123",
    "bairro": "Centro",
    "cidade": "Belo Horizonte",
    "estado": "MG",
    "cep": "30130-110"
  }
}
```

**Testes automatizados**
- Status 200
- `crp` é string
- `regimeTrabalho` é string

---

### PUT /psicologos/perfil

Atualiza o perfil profissional do psicólogo autenticado.

**Headers**
```
Authorization: Bearer {{token}}
Content-Type: application/json
```

**Request Body**
```json
{
  "crp": "06/12345",
  "especialidade": "Ansiedade e Depressão",
  "bio": "10 anos de experiência — atualizado",
  "regimeTrabalho": "REMOTO",
  "duracaoSessaoMin": 50,
  "valorSessao": 200.00,
  "aceitaEmergencia": true
}
```

**Response 200 — OK**
```json
{
  "id": "d4e5f6a7-b8c9-0123-defa-234567890123",
  "nome": "Dra. Ana Lima",
  "crp": "06/12345",
  "especialidade": "Ansiedade e Depressão",
  "bio": "10 anos de experiência — atualizado",
  "regimeTrabalho": "REMOTO",
  "duracaoSessaoMin": 50,
  "valorSessao": 200.00,
  "aceitaEmergencia": true,
  "endereco": null
}
```

**Testes automatizados**
- Status 200
- `valorSessao` igual a `200`

---

### DELETE /psicologos/delete/{usuarioId}

Remove o perfil do psicólogo. O usuário é mantido para preservar histórico.

**Headers**
```
Authorization: Bearer {{token}}
```

**Response 204 — No Content**

---

## 5. Health Check

### GET /actuator/health

Verifica o status da aplicação. Endpoint público — não exige token.

**Response 200 — OK**
```json
{
  "status": "UP"
}
```

**Testes automatizados**
- Status 200
- `status` igual a `"UP"`

---

## Resumo dos endpoints

| Método | Endpoint | Auth | Perfil | Descrição |
|---|---|---|---|---|
| POST | `/auth/registrar` | Não | — | Registra usuário + perfil |
| POST | `/auth/login` | Não | — | Autentica e retorna JWT |
| GET | `/usuarios/me` | Sim | Qualquer | Dados do usuário logado |
| PUT | `/usuarios/me` | Sim | Qualquer | Atualiza nome |
| GET | `/pacientes/perfil` | Sim | PACIENTE | Perfil completo do paciente |
| PUT | `/pacientes/perfil` | Sim | PACIENTE | Atualiza perfil do paciente |
| DELETE | `/pacientes/delete/{id}` | Sim | PACIENTE | Remove perfil do paciente |
| GET | `/psicologos` | Sim | Qualquer | Lista psicólogos ativos |
| GET | `/psicologos/perfil` | Sim | PSICOLOGO | Perfil do psicólogo logado |
| PUT | `/psicologos/perfil` | Sim | PSICOLOGO | Atualiza perfil do psicólogo |
| DELETE | `/psicologos/delete/{id}` | Sim | PSICOLOGO | Remove perfil do psicólogo |
| GET | `/actuator/health` | Não | — | Status da aplicação |

---

## Códigos de resposta utilizados

| Código | Significado | Quando ocorre |
|---|---|---|
| 200 | OK | Leitura ou atualização bem-sucedida |
| 201 | Created | Registro criado com sucesso |
| 204 | No Content | Deleção bem-sucedida |
| 400 | Bad Request | Dados inválidos ou campo obrigatório ausente |
| 401 | Unauthorized | Token ausente ou credenciais inválidas |
| 403 | Forbidden | Token válido mas sem permissão para o recurso |
| 404 | Not Found | Recurso não encontrado |
| 409 | Conflict | E-mail já cadastrado |

---

## Enums aceitos

**PerfilUsuario:** `PACIENTE` | `PSICOLOGO`

**RegimeTrabalho:** `PRESENCIAL` | `REMOTO` | `HIBRIDO`

**FormaPagamento:** `PIX` | `CARTAO_CREDITO` | `CARTAO_DEBITO` | `CONVENIO`

**StatusConsulta:** `SOLICITADA` | `CONFIRMADA` | `RECUSADA` | `EM_ANDAMENTO` | `CONCLUIDA` | `CANCELADA`