# NAT instance
module "hz-nat" {
  count         = var.use_nat_gateway ? 0 : 1
  source        = "hamdiz0/hz-nat-instance/aws"
  instance_type = var.nat_instance_type
  vpc_id        = aws_vpc.vpc.id
  map_subnet_rtbs = [
    ([ # public subnet id , private route tables ids 
      aws_subnet.public_subnet[0].id, [aws_route_table.private_rt.id]
    ])
  ]
}
# NAT gateway
resource "aws_eip" "nat_eip" {
  count  = var.use_nat_gateway ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = var.use_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    Name = "nat_gateway"
  }
}
resource "aws_route" "nat_gateway_route" {
  count                  = var.use_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[0].id
}