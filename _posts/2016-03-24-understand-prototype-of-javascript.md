---
layout: post
date: 2016-03-23 10:29:20 +0800
title: "浅谈JavaScript原型链机制"
tags: [Web, JavaScript, Prototype, 原型链]
categories: Knowledge
---

读了JavaScript高级程序一书，也浅谈下对JavaScript中原型链机制，以作总结。

<!-- more -->

## 一、函数的prototype属性

在我们创建的每个函数中，都有一个prototype(原型)属性，这个属性是一个对象，它的用途是来包含可以由特定类型的实例共享的属性和方法。也就是说，不用在构造函数中定义对象信息，而可以将这些信息直接添加到原型对象中，从而可以由该构造函数构造出来的所有对象共享，如：

```javascript
function Person(){}
Person.prototype.country = "America";
Person.prototype.showCountry = function(){
    alert(this.country);
}
 
var person1 = new Person();
var person2 = new Person();
person1.showCountry(); // America
person2.showCountry(); // America
```
由上述例子，Person的两个实例person1和person2共享了country属性和showCountry()方法。在上述例子中，构造函数中并没有country属性和showCountry()方法，由其构造的实例person1和person2中自然也不会有country和showCountry()方法，然而两个实例却都可以访问上述属性和方法，其实是访问的原型对象中的country属性和showCountry()方法。

我们说，每一个创建的函数中，都会自动生成一个prototype属性，该属性指向一个原型对象。而在该原型对象中又会有一个constructor属性，它指向该原型对象的引用所在的函数。就上例而言，Person会有一个prototype属性，指向其实例的原型对象，而在这个原型对象中，又有一个constructor属性，它又指向Person。

## 二、对象的__proto__属性

自定义的构造函数，其原型属性(prototype)默认只会得到一个constructor属性，至于其他的方法，都是从Object对象继承而来。而由该构造函数生成的新实例，默认会有一个_指针属性(在Firefox、Safari、Chrome和Flash的ActionScript中，是`__proto__`，并且通过脚本可以取到，而在其他实现中，这个属性对脚本则是完全不可见的)，它也指向其构造函数的原型属性。

下图表明了 "构造函数"、"构造函数的原型属性"、"实例"， 三者之间的关系：

![构造函数、构造函数的原型属性、实例之间的关系][Constructor-Prototype-Instance]

可见看到，实例的__proto__属性并非实例和构造函数之间的连接，而存在于实例与构造函数的原型属性。简单验证：

```javascript
alert(person1.__proto__ == person2.__proto__); // true
alert(person1.__proto__ == Person.prototype); // true
alert(Person.prototype.constructor == Person); // true 
```

有些实现无法通过脚本访问到本质的`__proto__`属性，但是，所有的实现却都支持用构造函数的原型属性的isPrototypeOf()方法来确定对象间是否存在这种关系。如：

```javascript
alert(Person.prototype.isPrototypeOf(person1)); // true
```

## 三、对象访问属性的原则

实例对象访问属性的时候会执行一次搜索：

1. 按属性名，即key，在实例对象中搜索该属性，如果搜索到则返回对应的value
1. 如果在实例对象中没有搜到，则顺着本质上的`__proto__`属性找到原型对象，从原型对象中搜索key

**这正是多个对象实例，共享原型所保存的属性和方法的基本原理。**

## 四、关于属性访问原则的几个注意点

1. 对象实例添加属性，屏蔽掉原型中的同名属性的，注意这里并非修改了原型中的属性值

```javascript
person1.country = "China";
person1.showCountry(); // "China" --- 来自实例
person2.showCountry(); // "America" --- 来自原型
```

2. 通过delete操作符而不是修改实例属性只为null，来重新访问同名的原型属性

```javascript
person1.country = null; // 只是修改了实例属性而非原型中的属性值
person1.showCountry(); // null --- 来自实例
 
delete person1.country; // delete 操作符，完全删掉该实力属性
person1.showCountry(); // "America" --- 来自原型
 
person2.showCountry(); // "America" --- 来自原型
```

## 五、判断一个属性的存在情况

1. 判断对象能否访问给定名的属性：使用in操作符

2. 判断一个属性是否存在于对象的实例属性hasOwnProperty()方法

```javascript
function Person(){}
Person.prototype.name = "Angela";
Person.prototype.showName = function(){
    alert(this.name);
};
var person = new Person();
// 1. "name" 为原型属性
alert("name" in person);//true
alert(person.hasOwnProperty("name")); // false
// 2. person1 的 "name" 为实例属性(屏蔽掉了原型属性)
 person.name = "Isabel";
alert(person.name); // "Isabel"
alert("name" in person); // true
alert(person.hasOwnProperty("name")); // true
// 3. 删除实例属性 "name"
delete person.name;
alert(person.name); // "Angela"
alert("name" in person); // true
alert(person.hasOwnProperty("name")); // true
```

3. 可以仿照hasOwnProperty()方法写一个hasPrototypeProperty()方法，判断是否访问的是原型属性:

```javascript
function hasPrototypeProperty(object, propertyName){
    // 非实例属性，而又能被对象访问，则返回true
    return (!object.hasOwnProperty(propertyName)) && (propertyName in object);
}
```

## 六、更简单的原型语法

如果需要给原型添加很多属性，每次都用Person.prototype可能会很麻烦，更简单语法是:

```javascript
function Person(){}
Person.prototype = {
   name: "Angela",
   showName: function(){
       alert(this.name);
   }
};
```

然而，前面说过每个函数都会获得一个默认的prototype属性，该prototype属性中又包含了一个constructor属性，指向原来的函数。而这里相当于创建了个“对象字面量”，赋值给了Person.prototype，本质上完全重写了prototype对象，它的constructor属性也不再指向Person了，而是指向Object，尽管instanceof仍然能得到正确的结果：

```javascript
alert(person instanceof Object); // true
alert(person instanceof Person); // true
alert(Object.getPrototypeOf(person).constructor == Object); // true
alert(person.constructor == Person); // false
```
> 　Note：上面两种方式都可以获取到对象的constructor

如果constructor很重要，可以在赋值对象中显示添上constructor属性，如：

```javascript
function Person(){}
Person.prototype = {
	constructor: Person, // 在对象字面量中添加constructor属性
	name: "Angela",
	showName: function(){
	    alert(this.name);
	}
};
``` 
> Note: 经测，原始类型这种方法不可行，例如扩展String类型的方法，即使指定 `constructor: String` 也没用，还是老老实实的一个一个地在原型属性上扩张比较好。


## 七、原型的动态性

```javascript
function Person() {}
var person = new Person(); // 先定义了一个Person实例对象
Person.prototype.sayHello = function(){
   alert("Hello");
}; // 然后才给原型添加方法
person.sayHello(); //" Hello"
```

虽然先定义了的Person的实例对象，然后才给原型添加的方法，但是，实例仍然能够访问到该方法。这是由于原型的动态性。**原理：对象访问的原则。**

## 八、原型对象的问题

原型的最大问题是由其共享的本性所导致的。原型中的属性被所有实例共享，事实上，这只对于方法很合适，对于基本值属性也可以(因为只要向实例中添加一个同名属性就可以屏蔽掉原型中的该属性)，然而对于引用类型的属性来说，却有不小的问题：

```javascript
function Person(){}
Person.prototype = {
    constructor: Person,
    name: "Elena",
    friends: ["Caroline", "Bonnie"],
    showName: function(){
        alert(this.name);
    }
};
var person1 = new Person();
var person2 = new Person();
```

如上例，现在需要给person1的friends属性中添加一个”Katherine”，可以有两种方法来：

```javascript
// 1.修改方式1
person1.friends = ["Caroline", "Bonnie", "Katherine"];
document.writeln(person1.friends+"<br/>"); // Caroline,Bonnie,Katherine
document.writeln(person2.friends+"<br/>"); // Caroline,Bonnie

// 2. 修改方式2
person1.friends.push("Katherine");
document.writeln(person1.friends+"<br/>"); // Caroline,Bonnie,Katherine
document.writeln(person2.friends+"<br/>"); // Caroline,Bonnie,Katherine
```

如上，如果用第一种修改方式，当然没有问题，但是用第二种方式的时候，发现**虽然只修改了person1的friends属性，但是却引起了person2的friends同样发生了变化**。

这其实是由friends的”引用”类型所造成的：

1. 修改方式1中，实质是为实例person1添加了新属性friends，并为其赋值了一个新的数组，这一属性屏蔽了原型中的同名属性。
1. 修改方式二中，只是通过person1.friends引用修改了原型属性friends的属性值。

因此，最好少用单独的原型模式，最好的是构造函数模式与原型模式混合使用。


## 构造函数模式与原型模式混合使用

混合模式：构造函数模式用于定义实例属性，而原型模式用于定义方法和共享的属性。如：

```javascript
function Person(name, age, country) {
//实例属性用构造函数模式定义
    this.name = name;
    this.age = age;
    this.country = country;
    this.friends = ["Elena", "Bonnie"];
}
Person.prototype = {
//方法和需要共享的属性用原型模式定义
    constructor: Person,
    showName: function () {
        alert(this.name);
    }
};
var person1 = new Person("Damon", 170, "America");
var person2 = new Person("Stefan", 168, "America");
person1.friends.push("Caroline");
document.writeln(person1.friends + "<br/>"); // Elena,Bonnie,Caroline
document.writeln(person2.friends + "<br/>"); // Elena,Bonnie
document.writeln(person1.friends == person2.friends); // false
```

混合模式的两个主要好处：

1. 每个实例都会有一份自己的实例属性的副本，同时又共享着对方法的引用，不用既持有属性又持有方法，最大限度的节省了内存。
1. 混合模式还支持向构造函数传递参数

如上所述，经测，原始类型这种方法不可行，例如扩展String类型的方法，即使指定`constructor: String`也没用，还是老老实实的一个一个地在原型属性上扩张比较好。



[Constructor-Prototype-Instance]: constructor-prototype-instance.png "构造函数、原型、实例关系图"





