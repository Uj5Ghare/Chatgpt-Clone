FROM node:18-alpine AS builder                                      #stage 1
ARG BUILD_ENV=development                                           #define build argument to switch environments
WORKDIR /app                                                        #setting working directory to /app
ENV NODE_ENV=$BUILD_ENV \                                           #set NODE_ENV from build argument
    APP_PORT=3000 \                                                 #default port for dev
    BUILD_DIR=dist                                                  #set default build directory
RUN npm install -g typescript webpack                               #global tools for building
COPY package*.json ./                                               #copy package files to the container
RUN npm install                                                     #install dependencies
COPY . .                                                            #copy all source files (code, assets, etc.)
RUN npm run build                                                   #build the application (compile TypeScript, bundle assets)

FROM node:18-alpine AS production                                   #stage 2 (production)
WORKDIR /app                                                        #set working directory to /app
ENV NODE_ENV=production \                                           #set environment to production
    APP_PORT=8080 \                                                 #production port
    APP_SECRET_KEY=${APP_SECRET_KEY:-"default-secret"}              #use secret key (can be passed as an environment variable)
COPY --from=builder /app/package*.json ./                           #copy package.json from builder stage
RUN npm install --only=production                                   #install only production dependencies
COPY --from=builder /app/dist ./dist                                #copy built files (e.g., dist folder) from builder stage
EXPOSE 8080                                                         #expose port 8080 for the application
RUN addgroup -S appgroup && adduser -S appuser -G appgroup          #create non-root user and group
USER appuser                                                        #switch to non-root user
RUN chown -R appuser:appgroup /app                                  #set correct permissions for appuser
CMD ["node", "dist/index.js"]                                       #start the app using Node.js

FROM node:18-alpine AS tester                                       #stage 3 (testing)
WORKDIR /app                                                        #set working directory for testing
RUN npm install -g mocha jest                                       #install global testing tools
COPY . .                                                            #copy all source files, including tests
RUN npm run test                                                    #run unit tests using the defined test script in package.json

FROM node:18-alpine AS cache                                        #stage 4 (cache management)
WORKDIR /app                                                        #set working directory
COPY package*.json ./                                               #copy package files for caching
RUN npm install                                                     #install dependencies

FROM node:18-alpine AS final                                        #final production image
WORKDIR /app                                                        #set working directory
COPY --from=production /app /app                                    #copy everything from production stage
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
CMD curl --fail http://localhost:8080/health || exit 1              #health check for container
EXPOSE 8080                                                         #expose the production port
USER appuser                                                        #run as non-root user in final image
CMD ["node", "dist/index.js"]                                       #start the app using Node.js
