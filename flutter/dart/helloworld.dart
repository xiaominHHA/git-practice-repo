void main() {
  int a = 10;
  String b = "Hello World";
  print("This is $a in $b");
  buildHouse(nums: 10);
}

void buildHouse({required int nums, String name = "deaultName"}) {
  print("I want to build a house for $name, building $nums floors");
}

class Robot {
  String name;
  int battery;
  Robot({required this.name, required this.battery});

  void introduce() {
    print("Hi, I am $name, current battery is $battery");
  }
}
