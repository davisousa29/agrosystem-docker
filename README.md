# AgroSystem — Infraestrutura Docker

Monorepo contendo a infraestrutura base do AgroSystem: uma plataforma de gestão agropecuária com dois apps mobile (consultor agro e fazendeiro) e uma API Laravel centralizada.

---

## Estrutura do projeto

```
agro-system/
├── docker-compose.yml           # Orquestrador principal
├── docker-compose.arm64.yml     # Override para Apple Silicon / AWS Graviton
├── docker-compose.x86.yml       # Override para Intel / AMD
├── .env                         # Variáveis do Docker Compose (raiz)
├── .env.example                 # Modelo de variáveis
├── Makefile                     # Atalhos de comandos
├── backend/                     # API Laravel 13 + PHP 8.4
│   ├── Dockerfile
│   └── ...                      # Arquivos do Laravel
├── nginx/                       # Proxy reverso
│   ├── Dockerfile
│   └── nginx.conf
├── app-consultorAgro/           # App React Native (Expo) — consultor agropecuário
└── app-fazendeiro/              # App React Native (Expo) — fazendeiro
```

---

## Pré-requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/) (para os apps mobile futuramente)

---

## Serviços

| Serviço    | Descrição                          | Porta exposta |
|------------|------------------------------------|---------------|
| `nginx`    | Proxy reverso                      | 80            |
| `backend`  | API Laravel 13 / PHP 8.4 (FPM)    | —             |
| `postgres` | Banco de dados PostgreSQL 16       | 5432          |
| `redis`    | Cache e filas                      | 6379          |

---

## Instalação e configuração

### 1. Clonar o repositório

```bash
git clone <url-do-repositorio>
cd agro-system
```

### 2. Instalar o Laravel dentro da pasta backend

> Necessário apenas na primeira vez, após clonar o repositório em uma máquina nova.

```bash
# Move o Dockerfile temporariamente para a pasta raiz
mv backend/Dockerfile backend.Dockerfile.tmp

# Instala o Laravel via container do Composer
docker run --rm \
  -v "$(pwd)/backend:/app" \
  -w /app \
  composer:2 \
  composer create-project laravel/laravel . --prefer-dist

# Devolve o Dockerfile para a pasta backend
mv backend.Dockerfile.tmp backend/Dockerfile
```

### 3. Configurar variáveis de ambiente

Crie o `.env` da raiz a partir do modelo:

```bash
cp .env.example .env
```

Edite o `.env` da raiz e defina as senhas:

```dotenv
DB_DATABASE=agro_db
DB_USERNAME=agro_user
DB_PASSWORD=sua_senha_aqui

REDIS_PASSWORD=sua_senha_redis_aqui
```

Em seguida configure o `.env` do Laravel:

```bash
cp backend/.env.example backend/.env
```

Edite `backend/.env` com os seguintes valores — os hosts devem apontar para os nomes dos containers Docker:

```dotenv
APP_NAME="AgroSystem"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=agro_db
DB_USERNAME=agro_user
DB_PASSWORD=sua_senha_aqui

SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
CACHE_STORE=redis

REDIS_CLIENT=phpredis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=sua_senha_redis_aqui
```

> `DB_PASSWORD` e `REDIS_PASSWORD` devem ser **idênticos** nos dois arquivos `.env`.

---

## Subindo o ambiente

### Build das imagens (primeira vez ou após alterações no Dockerfile)

```bash
make build
```

### Subir os containers

```bash
make up
```

O Makefile detecta a arquitetura automaticamente (`arm64` ou `x86_64`). Para forçar manualmente:

```bash
make up-arm   # Apple Silicon / AWS Graviton (ARM64)
make up-x86   # Intel / AMD (x86_64)
```

### Gerar a chave da aplicação Laravel

```bash
make key
```

Após rodar, verifique se o `APP_KEY` foi preenchido em `backend/.env`:

```bash
grep APP_KEY backend/.env
```

Copie o valor gerado e cole também no `.env` da raiz.

### Rodar as migrations

```bash
make migrate
```

### Verificar se está tudo rodando

```bash
make ps
```

Todos os containers devem estar com status `Up` ou `healthy`:

```
agro_nginx     Up    0.0.0.0:80->80/tcp
agro_backend   Up
agro_postgres  Up (healthy)
agro_redis     Up (healthy)
```

Acesse [http://localhost](http://localhost) — deve aparecer a tela de boas-vindas do Laravel.

---

## Comandos disponíveis

| Comando        | Descrição                                          |
|----------------|----------------------------------------------------|
| `make up`      | Sobe os containers (detecta arquitetura)           |
| `make up-arm`  | Sobe forçando ARM64                                |
| `make up-x86`  | Sobe forçando x86_64                               |
| `make down`    | Derruba todos os containers                        |
| `make build`   | Reconstrói as imagens do zero                      |
| `make logs`    | Exibe logs em tempo real                           |
| `make ps`      | Lista o status dos containers                      |
| `make shell`   | Abre terminal dentro do container backend          |
| `make migrate` | Roda as migrations do Laravel                      |
| `make fresh`   | Recria o banco do zero + migrations + seeds        |
| `make seed`    | Roda os seeds                                      |
| `make test`    | Roda os testes do Laravel                          |
| `make key`     | Gera o APP_KEY do Laravel                          |

---

## Acesso aos serviços em desenvolvimento

| Serviço      | Endereço          | Credenciais             |
|--------------|-------------------|-------------------------|
| API Laravel  | http://localhost  | —                       |
| PostgreSQL   | localhost:5432    | conforme `backend/.env` |
| Redis        | localhost:6379    | conforme `backend/.env` |

---

## Solução de problemas comuns

**"File not found" ao acessar localhost**
Verifique se o volume do Nginx está montado corretamente no `docker-compose.yml`:
```yaml
nginx:
  volumes:
    - ./backend:/var/www/html
```

**"MissingAppKeyException"**
O `APP_KEY` está vazio ou divergente entre os arquivos `.env`. Rode `make key`, copie o valor gerado em `backend/.env` e cole também no `.env` da raiz. Depois rode `make down && make up`.

**Erro de plataforma no build (linux/amd64 vs arm64)**
Certifique-se de usar o override correto para sua arquitetura:
```bash
make up-arm  # Mac Apple Silicon
make up-x86  # Intel/AMD
```

**Conflito de porta 5432 ou 6379**
Algum serviço local (PostgreSQL ou Redis) está usando a mesma porta. Pare o serviço local ou altere a porta exposta no `docker-compose.yml`.

**"Project directory is not empty" ao instalar o Laravel**
A pasta `backend/` contém o `Dockerfile`. Mova-o temporariamente antes de instalar:
```bash
mv backend/Dockerfile backend.Dockerfile.tmp
# rode o comando de instalação do Laravel
mv backend.Dockerfile.tmp backend/Dockerfile
```

---

## Próximos repositórios

Este repositório contém apenas a infraestrutura base. Os projetos de código ficam em repositórios separados:

| Repositório              | Descrição                                 |
|--------------------------|-------------------------------------------|
| `agro-backend`           | API Laravel — código da aplicação         |
| `agro-app-consultorAgro` | App React Native — consultor agropecuário |
| `agro-app-fazendeiro`    | App React Native — fazendeiro             |