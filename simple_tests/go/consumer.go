package main

import (
  "fmt"
  "log"

  "github.com/streadway/amqp"
)

func failOnError(err error, msg string) {
  if err != nil {
    log.Fatalf("%s: %s", msg, err)
    panic(fmt.Sprintf("%s: %s", msg, err))
  }
}

func main() {
  conn, err := amqp.Dial("amqp://guest:guest@localhost:5672/%2Fplayground")
  failOnError(err, "Failed to connect to RabbitMQ")
  defer conn.Close()

  ch, err := conn.Channel()
  failOnError(err, "Failed to open a channel")
  defer ch.Close()

  q, err := ch.QueueDeclare(
    "my.little.go.queue", // name
    false,   // durable
    false,   // delete when usused
    false,   // exclusive
    false,   // no-wait
    nil,     // arguments
  )
  failOnError(err, "Failed to declare a queue")

  err = ch.QueueBind(
  q.Name, // queue name
  "",     // routing key
  "my.little.dead-pony.topic", // exchange
  false,
  nil)

  failOnError(err, "Failed to bind queue to exchange")

  msgs, err := ch.Consume(
    q.Name, // queue
    "",     // consumer
    true,   // auto-ack
    false,  // exclusive
    false,  // no-local
    false,  // no-wait
    nil,    // args
  )
  failOnError(err, "Failed to register a consumer")

  forever := make(chan bool)

  go func() {
    for d := range msgs {
      log.Printf("Received a message: %s", d.Body)
    }
  }()

  log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
  <-forever
}