// include terraform block below

provider "random" {}

resource "random_integer" "number" {
  min = 0
  max = 10000
}

output "number" {
  value = random_integer.number.result
}
