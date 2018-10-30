---
layout: post
date: 2018-07-31 19:56:02 +0800
title: "面向对象编程中的SOLID设计原则"
categories: [Strength]
tags: [oop, design principles, solid]
description: "面向对象程序设计中的 S.O.L.I.D 原则"
---

在软件的生命周期中，完成并不代表着结束，往往维护运营往往需要投入更多的成本，包括精力成本和时间成本。而一个遵循着好的开发规范以及拥有着良好设计原则的系统，往往可以节约大量的后期维护升级成本。说起设计，往往大家第一反应是设计模式，殊不知，二十几种设计其实都遵循着一些基本的设计原则。S.O.L.I.D，是事实证明的良好设计原则。

SOLID，每个字母分别对应于一个原则：
- S，SRP，Single Responsibility Principle
- O，OCP，Open/Closed Principle
- L，LSP，Liskov Substitution Principle
- I，ISP，Interface Segregation Principle
- D，DIP，Dependency Inversion Principle

下面分别详述其含义。

## SRP，单一职责原则

SRP states that every class should have a single responsibility. There should never be more than one (design-related) reason for a class to change. 意为每个类应该有且仅有一个职责，只负责该职责相关的事情。在设计上，不应该有多于一个原因导致该类的变化。

这个原则相对简单，比如一家餐厅，服务生负责为客人点餐倒水，保洁负责收拾桌子，厨师负责料理，收银员负责收银，财务负责核账。一般而言，越大型的软件设计，职责划分就越细致。这样不会因为收银方式变更，导致厨师重新培训，在软件开发中则不用因为一个类或者模块变更导致整个软件都要进行重新测试。

## OCP，开闭原则

OCP states that objects or entities should be open for extension, but closed for modification. 意为软件中的对象或实体，比如类、模块、函数等，要尽量`允许扩展`而`避免更改`。按照这个原则，当我们需要为某个模块/类添加某个行为时，应该是通过增加一个类/方法而不是修改既有的某个类/方法达成目标。

这个原则，在我们的软件开发过程中，应该是很常见的，尤其是在使用第三方库的时候，会发现，一个优秀的第三方库，有一个更优的算法时，往往会增加一个新的类/方法去实现该算法并建议使用它，而不是直接修改旧有的算法类/方法。如果不遵循该原则，直接大刀阔斧地修改了某对象的行为，而恰巧该对象被系统的其他部分依赖怎么办？那岂不是要更改每一处对该对象行为的引用的地方，再检查逻辑是否因此变化，还得再做一堆的测试，凭空增加了工作量。

## LSP，里氏替换原则

LSP states that objects in a program should be replaceable with instances of their subtypes without altering the correctness of the program. 该原则是说，在程序中，对象应该都是可以用它们的子类型来替换，而不影响程序的正确性，即不出异常不报错。

理论上来讲，如果父类能实现的逻辑，子类同样也能实现，那么它们才具备父子关系，否则请移除其父子关系。例如，有这样一句话『我用枪击杀了敌人』，其中的『枪』，我可以换成『手枪』、『狙击枪』，这样没问题，所以在这个系统中，枪和手枪、狙击枪之间可以有继承关系，如果我说『我用道具枪击杀了敌人』，因为道具枪不能杀人，显然这句话就出现了明显的逻辑漏洞，据此，在这句话所构成的系统中，水枪不能和枪成为父子类型的关系。当然，在不同的系统中，父子关系是不一定的，所以里氏替换原则，也只需要在特定系统中遵循即可。例如，『我听到了一声枪响』，在这个系统中，即使是演电影的道具枪，也可以有枪响，所以它就和枪具备了可替换性。

## ISP，接口隔离原则

ISP states that many client-specific interfaces are better than one general-purpose interface. 意为许多客户特定的接口，要优于一个大而全的通用目的的接口。分拆合理的接口，能避免任意的实现，都需要实现一大堆根本不需要但又不得不去实现的方法。

这么理解，现在有一个系统，想要描述自然界各类动物的移动行为，我们看下面两种方式哪个更好一些。
方式一，只定义一个 Moveable ，描述动物有飞、走、游三种不同的移动方式：
```java
public interface Moveable {
    void fly();
    void walk();
    void swim();
}
```
方式二，定义飞会飞的 Flyable ，会走的 Walkable ，会游的 Swimmable
```java
public interface Flyable {
    void fly();
}
public interface Walkable {
    void walk();
}
public interface Swimmable {
    void swim();
}
```

OK，我现在想描述具体的鲸鱼的移动方式，如果按照方式一，我可能需要些一个 Whale 类，去实现其中的所有三个方法，而事实上，fly() 和 walk() 方法，与鲸毫无关系。而第二种方式，我知道鲸是游的，那么只需要去实现 Swimmable 接口，并实现其中的 swim() 方法即可。同理，当描述麻雀、大象时，只需要分别实现对应的 Flyable 和 Walkable， 而对于青蛙这种既会游又会走的，只需要实现 Swimmable 和 Walkable 两个接口即可完美描述其移动方式。

值得说明的一点是，该原则中的接口并不特指 Java 中的 interface ，而是类似于 API 中的 `I`一样的泛义的接口，抽象类甚至具体实现类都可能包含在这个概念中。

## DIP，依赖倒置原则

DIP states that the high level module must not depend on low level module, but they should depend on abstractions. 即高层模块不能依赖于具体的底层模块，而是应该依赖于底层模块的抽象。换句话说，要尽量使用抽象最小化对象之间的依赖。

例如现在有一个 App 类，这个类可能有发邮件（Email）、发短信（SMS）、数据入库（Database）等操作，其中我们认为 Email/SMS/Database 都是具体的特定类，与其让 App 类去依赖于这三个具体的类，DIP 指导我们对这三个具象类抽象出一个 Service 类。如此一来，App 只依赖于一个抽象类 Service。这样的好处显而易见，我们不仅能随时替换 Service 的功能（想发邮件发邮件、想发短信发短信、想数据入库就入库），甚至还能扩展功能，比如添加日志，审计功能。


遵循良好的设计原则，有利于我们平常在开发中写出更可维护的代码，便于团队协作也有利于后来者。道理上讲，设计模式、设计原则等等，也理应成为OOP程序员之间的常用术语，这样一来，才能显得更具专业性。
