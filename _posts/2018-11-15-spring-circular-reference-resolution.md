---
layout: post
date: 2018-11-15 15:04:06 +0800
title: "Spring中循环引用的解决方案"
tags: ["circular reference", "循环引用"]
categories: Knowledge
---

基于 Springframework 的应用开发，尤其在系统比较复杂时，可能会出现 Bean 循环引用的情形。

正常引用依赖关系：
> Bean A → Bean B → Bean C

循环引用依赖关系：
> Bean A → Bean B → Bean A

我们知道 Spring 应用在启动时，即会创建 Spring context，加载并实例化 Bean。
正常引用依赖关系中，Spring 尝试实例化 A，发现其依赖 B，则会尝试实例化 B，又发现其依赖 C，则会尝试实例化 C。最终 Spring 会依次创建 bean C，B，A。
而循环引用依赖关系中，Spring 尝试实例化 A，发现其依赖 B，则会尝试实例化 B，又发现其依赖 A，则会尝试实例化 A。最终，Spring 无法决定究竟该先实例化 A 还是先实例化 B。

<!-- more -->

Spring 在遇到循环引用时，会直接抛出 BeanCurrentlyInCreationException 异常，如：
```
org.springframework.beans.factory.BeanCurrentlyInCreationException: Error creating bean with name 'beanOne':
 Requested bean is currently in creation: Is there an unresolvable circular reference?
```

来看一个使用使用构造器注入引发循环引用的例子：
```java
@Component
public class BeanOne {
    private final BeanTwo beanTwo;

    public BeanOne(BeanTwo beanTwo) {
        this.beanTwo = beanTwo;
    }
}

@Component
public class BeanTwo {
    private final BeanOne beanOne;

    public BeanTwo(BeanOne beanOne) {
        this.beanOne = beanOne;
    }
}
```
BeanOne 和 BeanTwo 相互依赖。

解决循环引用，有多种方法：
- 使用 Field/Setter 注入
- 使用 @PostConstruct 注解
- 使用 @Lazy 注解

## 使用 Field/Setter 注入解决循环引用问题

最常用的解决循环引用的方法，就是使用字段注入或者设置方法注入。
使用 Field 注入，修改代码，去掉依赖彼此的构造方法：
```java
@Component
public class BeanOne {
    @Autowired
    private BeanTwo beanTwo;
}

@Component
public class BeanTwo {
    @Autowired
    private BeanOne beanOne;
}
```

类似的，使用 Setter 注入：
```java
@Component
public class BeanOne {
    private BeanTwo beanTwo;

    @Autowired
    public void setBeanTwo(BeanTwo beanTwo) {
        this.beanTwo = beanTwo;
    }
}

@Component
public class BeanTwo {
    private BeanOne beanOne;

    @Autowired
    public void setBeanOne(BeanOne beanOne) {
        this.beanOne = beanOne;
    }
}
```

这两种方式解决思路是一致的，使用默认的无参构造器实例化 bean，此时无需保证其依赖的 bean 已被实例化。Field 注入本质上和 Setter 注入是一样的。

## 使用 @PostConstruct 注解

修改示例代码如下：
``` java
@Component
public class BeanOne {
    private final BeanTwo beanTwo;

    public BeanOne(BeanTwo beanTwo) {
        this.beanTwo = beanTwo;
    }

    @PostConstruct
    public void init() {
        beanTwo.setBeanOne(this);
    }
}

@Component
public class BeanTwo {
    private BeanOne beanOne;

    public void setBeanOne(BeanOne beanOne) {
        this.beanOne = beanOne;
    }
}
```

可见，BeanOne 实例化时使用构造器注入 beanTwo，而 BeanTwo 实例化时则使用的是默认的无参构造器，没有依赖 beanOne 产生依赖。那么具体使用时，BeanTwo 的实例中，其 beanOne 属性为 null ？并不是。注意到 BeanOne 中有一个使用 @PostConstruct 标注的 init() 方法，查看其该注解的源码注释：
```
The PostConstruct annotation is used on a method that needs to be executed after dependency injection is done to perform any initialization....
```

使用 @PostConstruct 标注的方法，会在依赖注入之后执行，用于某些初始化操作。在这里，这所谓的“初始化”操作，就是为 beanTwo 的 beanOne 属性赋值。

## 使用 @Lazy 注解

修改代码如下：
```java
@Component
public class BeanOne {
    private final BeanTwo beanTwo;

    public BeanOne(BeanTwo beanTwo) {
        this.beanTwo = beanTwo;
    }
}

@Component
public class BeanTwo {
    private final BeanOne beanOne;

    @Lazy
    public BeanTwo(BeanOne beanOne) {
        this.beanOne = beanOne;
    }
}
```

注意到，修改后的代码，与一开始的引发循环引用异常的代码几乎完全相同，差异仅在于 BeanTwo 构造方法上面的 @Lazy 注解。顾名思义，该注解表明这个构造注入懒执行。

查看其源码注释：
```
Indicates whether a bean is to be lazily initialized.
```

查看其源码：
```java
@Target({ElementType.TYPE, ElementType.METHOD, ElementType.CONSTRUCTOR, ElementType.PARAMETER, ElementType.FIELD})
```

可见 @Lazy 注解，标示一个 Bean 是否被懒初始化。该注解可用于 类型、方法、构造器、参数、字段等目标，在本例中，用在构造器上，表示只有需要用到该类实例时才进行调用该构造器进行实例化操作。所以在该实例中，可能的实例化过程如下：
分析过程： 
> Start: 尝试实例化 beanOne → 发现需要依赖 beanTwo → 尝试实例化 beanTwo 
> Start: 尝试实例化 beanTwo → 发现 @Lazy 注解，暂不实例化；

实例化过程： 
> 实例化 beanTwo → 实例化 beanOne

简言之，使用 @Lazy 标注的类，不会在容器中主动触发实例化，只有当被使用到/被依赖到时，被动触发实例化。

综上，介绍了三种（或四种）解决 Spring 应用中循环引用的方案，并没有优劣之分，可以根据自己的喜好自由选择。此外，@Lazy 注解还有很多细节原理可以挖掘，且再觅机会介绍了。
