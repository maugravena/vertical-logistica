# Desafio Técnico Luizalabs - Vertical Logística

- Projeto desenvolvido com a mais recente de Rails (versão 8)
- Banco de dados padrão do Rails SQLite para ambiente de desenvolvimento
- RSpec para os testes automatizados

## Arquitetura

Analisando o conjunto de dados do arquivo posicional entendi cada linha do arquivo como uma transação de venda relacionada a
pedido e usuários.

- Models: User`, `Order`, `Product`, `OrderItem`
- Controllers
  - `TransactionsController`: responsável por disponibilizar os dados salvos a partir do conteúdo da importação do arquivo.
  - `ImportsController`: Faz o parser dos dados do arquivo posicional e salva os dados estruturados no banco.

Organização do código em Services, a ideia é ter um controller com pouco código e sem lógica de negócios. Abordagem
influenciada pelo Princípio da Responsabilidade Única.

- **`Transaction::Parser`**: Responsável por interpretar e validar os dados de entrada durante a importação.
- **`Transaction::Persistence`**: Gerencia a persistência de dados no banco

Pré-requisitos

- Ruby 3.4.3
- Rails 8.0.1

## Passos para rodar a aplicação localmente

1. fazer o build da imagem

```
docker-compose build
```

2. Subir a aplicação

```
docker-compose up
```

Após esses comandos a aplicação ficará disponivel em `http://localhost:3000`.

### Testes

```
docker-compose run --rm web rspec
```

## Endpoints

### **1. Importação de Transações**
- **Endpoint**: `POST /imports/transactions`
- **Descrição**: Importa dados de transações.
- **Exemplo de Payload**:
  ```txt
  0000000070                              Palmer Prosacco00000007530000000003     1836.7420210308
  0000000075                                  Bobbie Batz00000007980000000002     1578.5720211116
  0000000049                               Ken Wintheiser00000005230000000003      586.7420210903
  0000000014                                 Clelia Hills00000001460000000001      673.4920211125
  0000000057                          Elidia Gulgowski IV00000006200000000000     1417.2520210919
  0000000080                                 Tabitha Kuhn00000008770000000003      817.1320210612
  0000000023                                  Logan Lynch00000002530000000002      322.1220210523
  0000000015                                   Bonny Koss00000001530000000004        80.820210701
  0000000017                              Ethan Langworth00000001690000000000      865.1820210409
  0000000077                         Mrs. Stephen Trantow00000008440000000005     1288.7720211127
  ```

```bash
curl --request POST \
  --url http://localhost:3000/imports/transactions \
  --header 'Content-Type: text/plain' \
  --header 'User-Agent: insomnia/10.3.1' \
  --data '0000000070                              Palmer Prosacco00000007530000000003     1836.7420210308
0000000075                                  Bobbie Batz00000007980000000002     1578.5720211116
0000000049                               Ken Wintheiser00000005230000000003      586.7420210903
0000000014                                 Clelia Hills00000001460000000001      673.4920211125'
```

### **2. Consulta de Pedidos**
- **Endpoint**: `GET /transactions`
- **Descrição**: Retorna pedidos com filtros opcionais.
- **Parâmetros de Filtro**:
  - `order_id`: Filtra por ID do pedido.
  - `start_date` e `end_date`: Filtram por intervalo de datas.
- **Exemplo de Resposta**:
  ```json
  [
    {
      "user_id": 1,
      "name": "Zarelli",
      "orders": [
        {
          "order_id": 123,
          "total": "1024.48",
          "date": "2021-12-01",
          "products": [
            { "product_id": 111, "value": "512.24" },
            { "product_id": 122, "value": "512.24" }
          ]
        }
      ]
    }
  ]
  ```

```bash
curl --request GET \
  --url 'http://localhost:3000/transactions?start_date=2021-06-18&end_date=2021-10-07' \
  --header 'Accept: application/json'
```

## Melhorias

- Implementar cache/paginação para consulta das orders sem filtro
- Adicionar validação antes de salvar os dados
- Substituir importação de dados síncrona por fluxo async utilizando ferramentas com Sidekiq
