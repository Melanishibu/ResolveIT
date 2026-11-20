# Introduction 
TODO: Give a short introduction of your project. Let this section explain the objectives or the motivation behind this project. 

# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Run the backend locally
Prerequisites: JDK 21 and Docker Desktop (running). Commands are for Windows PowerShell, from the repo root.

1. Start PostgreSQL 17 and Mailpit: `docker compose up -d`
   - PostgreSQL on `localhost:5432`, database/user/password `resolveit` (dev only)
   - Mailpit SMTP on `localhost:1025`, web UI at http://localhost:8025
2. Start the backend with the `dev` profile: `cd backend; .\mvnw.cmd spring-boot:run`
3. Check it:
   - Health: http://localhost:8080/api/v1/health returns `{"status":"UP"}`
   - OpenAPI JSON: http://localhost:8080/api/docs, Swagger UI: http://localhost:8080/api/docs/ui
4. Stop the database: `docker compose down` (add `-v` to delete its data volume)

Configuration comes only from environment variables: `RESOLVEIT_DB_URL`, `RESOLVEIT_DB_USERNAME`,
`RESOLVEIT_DB_PASSWORD`, `SERVER_PORT` (default 8080). The `dev` profile supplies the local defaults above;
without it, the database variables are required.

Build and test (unit, integration, ArchUnit, Spring Modulith and error-gate tests; needs Docker for
Testcontainers): `cd backend; .\mvnw.cmd clean verify`. Tests always run with the `test` profile, never `dev`.

Error codes: the registry `ErrorCodeRegistry` is published as `contracts/error-codes.json`. After changing
the registry, regenerate the file with `cd backend; .\mvnw.cmd test "-Dtest=ErrorCodeContractTest" "-DupdateContracts=true"`
and commit it.

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)