FROM node:20-alpine

WORKDIR /usr/src/app

# Copia os arquivos de dependências
COPY package*.json ./

# Instala as dependências
RUN npm install

# Copia todo o resto do projeto (incluindo src, app.js, etc)
COPY . .

# Expõe a porta do Express
EXPOSE 3000

# Comando para iniciar
CMD ["npm", "run", "dev"]