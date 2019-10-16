---
layout: post
date: 2018-10-11 18:29:15 +0800
title: "基于SpringBoot微服务开发中的异常处理最佳实践"
tags: [SpringBoot, RESTful, 错误码, 异常处理]
categories: Practice
---

本文通过对RESTful WebService中异常处理的几个关键点如自定义错误码、定制错误消息、自定义异常、全局异常处理进行介绍，与读者分享本人对Spring异常处理和对RESTful API设计的思考和实践。

随着前后端分离，前端工程化，后端微服务化，越来越多的应用都开始倾向于使用 RESTful API 为各种各样的客户端提供服务。设计一套优雅的 API 服务，需要诸多考量，而异常处理往往被忽视，而我认为这恰恰是评判一套 API 设计好坏的很重要的一个衡量因素。经过很多的经验借鉴和思考，最终形成了一套我认为还算合理的异常处理方式，权作抛砖引玉。

<!-- more -->

本文虽然名为 Spring Boot 异常处理最佳实践，但并不仅限于 Spring Boot 应用，普通的 Spring RESTful Webservice 也都可以采用此实践。对于异常处理，最关键的无非是定义错误码、定制错误消息、自定义异常类几个环节，关于这些点，以及其中可能遇到的问题，笔者在写作此文之前，都是经过了深思熟虑的，也都尽可能在文章中或者在代码中指出来了，供读者参考。

## 错误码

当我们的 API 提供给调用方使用的时候，除了正确的请求、响应接口说明以及示例，还应该给出一个符合统一规范的错误消息说明和一组错误码说明。可能有人习惯使用数字作为错误码，但理论上讲，无论是接口还是数据库，使用本身无意义的数字作为字段值，都属于非常糟糕的设计。关于这点，有必要解释一下。设想如下场景，我们设计了一张表，其中很多枚举字段，假如都使用数字来存储，比如某个 Task 的执行状态可能有[1-就绪；2-执行中；3-故障恢复中；4-已完成]几种，那么这种设计只会接下来会面临两种情况：

1. 服务接口代码中不做翻译，则如果你提供的是 API，则用户拿到你的数据之后，不得不对照着你的文档，才能明白每个值代表什么含义，如果你的接口是给前端使用的，那么前端必须按照你的接口文档去维护一个翻译列表。更糟糕的是，如果有一天你的状态多了一种，比如失败重试太多次后中止任务[5-已中止]，如果前端未更新翻译列表，则好的情况是前端做了容错，在页面上显示`5`，坏的情况是直接就在页面显示了 `undefined`。
2. 服务接口代码中做翻译，你可能需要在代码中写大量的代码做 IN OUT 两个方向上的翻译工作。

而如果设计之初，就将该状态字段的值设置为了有意义的字符串枚举呢？如[READY;RUNNING;RETRYING;FAILBACK;DONE]，则按照上述情况1，用户拿到数据后，一目了然就能知晓当前状态是怎样的。如果是前端使用接口，即使状态增加[ABORT]时，即使前端未及时更新翻译列表，页面上直接显示`ABORT`，也不至于使用户莫名其妙。
总而言之，以数字作为枚举值的做法，绝大多数情况都可以归为陋习（不排除个别特殊情况）。回到错误码的讨论上，抛弃旧有的以数字作为错误码的古董观念吧！我们定义错误码枚举包含两个字段： `code` 字段给出简明扼要的错误提示，`message` 字段描述具体错误，形如：
```java
INVALID_REQUEST("InvalidRequest", "Invalid request, for reason: {0}")
```

## 错误消息

对于 HTTP 请求而言，正确响应一般都伴随着2xx状态码，以及一个响应消息体。相应地，错误响应也理应有一个*错误消息*，以便 API 使用者能够知道错误原因，做出修正。当然，错误响应的响应状态码也是必不可少的，且原则上，应该尽可能地返回恰当的 HTTP 状态码，但这并不是我们本文讨论的重点，有兴趣的可以仔细阅读下 RFC 文档。至于*错误消息*，则没有一个特定的格式。

我们定义错误响应的消息体如下：
```json
{
    "requestId": "5f8c89b6-f0d4-48d4-b945-01fbce035c0a",
    "status": 400,
    "reason": "Bad Request",
    "code": "NotFound",
    "message": "Resource Book[id=10] not found.",
    "details": "uri=/books/10;client=0:0:0:0:0:0:0:1",
    "timestamp": "2018-10-16T23:30:40.431+08:00"
}
```
> 注：这里只做一个示例，讲述实践方法，具体的错误消息可以根据自己的需要定制。

## 具体实现

继上述说明，我们接下来用代码说明具体如何实现。该项目为 Maven 多模块项目，文件结构如下
```
.
├── README.md
├── errorhandle-bookstore
│   ├── pom.xml
│   └── src
│       ├── main
│       │   ├── java
│       │   │   └── com
│       │   │       └── lomagicode
│       │   │           └── example
│       │   │               └── errorhandle
│       │   │                   └── bookstore
│       │   │                       ├── ErrorHandleApplication.java
│       │   │                       ├── config
│       │   │                       │   ├── ValidationConfig.java
│       │   │                       │   └── WebMvcConfig.java
│       │   │                       ├── domain
│       │   │                       │   └── Book.java
│       │   │                       ├── error
│       │   │                       │   ├── BookStoreErrorCode.java
│       │   │                       │   └── RestExceptionHandler.java
│       │   │                       ├── service
│       │   │                       │   ├── BookService.java
│       │   │                       │   └── BookServiceImpl.java
│       │   │                       └── web
│       │   │                           └── endpoint
│       │   │                               └── BookEndpoint.java
│       │   └── resources
│       │       └── application.properties
│       └── test
│           └── java
├── errorhandle-commons
│   ├── pom.xml
│   └── src
│       ├── main
│       │   ├── java
│       │   │   └── com
│       │   │       └── lomagicode
│       │   │           └── example
│       │   │               └── errorhandle
│       │   │                   └── commons
│       │   │                       ├── constant
│       │   │                       │   └── WebConsts.java
│       │   │                       ├── error
│       │   │                       │   ├── BusinessException.java
│       │   │                       │   ├── CommonErrorCode.java
│       │   │                       │   ├── CustomizedBaseExceptionHandler.java
│       │   │                       │   ├── ErrorCode.java
│       │   │                       │   └── ErrorDetails.java
│       │   │                       ├── package-info.java
│       │   │                       └── web
│       │   │                           └── interceptor
│       │   │                               └── RequestIdInterceptor.java
│       │   └── resources
│       └── test
│           └── java
└── pom.xml
```

对于一个大中型项目而言，通常我们可以把项目看做一个产品，而产品往往会根据业务分为不同的子模块。对于错误码的定义，通常会分为通用错误码、以及模块内的业务错误码。模拟一个大中型产品，我们这里将项目分为最基本的两个模块，一个代表公用模块，对于通用错误码、通用异常、通用异常处理以及对错误消息通用格式的定义等，我们都会在这个模块中实现。一个模拟的书店模块，依赖前面的公用模块。

为尽量避免通篇大量的代码粘贴，我们在这里只介绍几个重要的文件，具体的实现细节，文章会在最后附上源码地址。

### 公共模块
公共模块，或者叫通用模块，包括三个重要的子包，`constant`、`error`、`web`，我们错误处理实现的主要代码就是在 `error` 包下。其中：

`ErrorCode` 是一个接口，作为错误码枚举类型的父接口，其中只有两个方法
```java
public interface ErrorCode {

    String getCode();

    String getMessage();
}
```

`CommonErrorCode` 中定义通用错误码，作为产品各个子业务模块的公用部分，如
```java
    /**
     * 错误请求
     */
    INVALID_REQUEST("InvalidRequest", "Invalid request, for reason: {0}"),
    /**
     * 参数验证错误
     */
    INVALID_ARGUMENT("InvalidArgument", "Validation failed for argument [{0}], hints: {1}"),
    /**
     * 未找到资源
     */
    NOT_FOUND("NotFound","Resource {0} not found."),
    /**
     * 未知错误
     */
    UNKNOWN_ERROR("UnknownError", "Unknown server internal error.");
```

`BusinessException` 是产品业务层面错误处理的通用异常类，是一个非受检异常。`BusinessException` 与系统默认异常最大的不同之处就是包含了一个 `errorCode` 属性。在业务中出错的地方，抛出一个携带有特定错误码的 `BusinessException` 异常，然后全局处理该异常类型，从其中解析构造出我们想要的错误消息，由 Spring 直接返回出去，即为一个符合我们要求的错误消息。

`CustomizedBaseExceptionHandler` 继承自 `org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler`，从名称上也可以看出来，`ResponseEntityExceptionHandler` 是一个用于全局处理 RESTful 接口异常的处理器。通过在该类型及其子类型中添加使用 `@ExceptionHandler` 注解的方法，可以处理指定异常类型。

`ErrorDetails` 自定义的错误消息体，可以根据自己的实际需要随意定制。

### 业务模块

业务模块中，其他部分可以从略，我们关注这么几个类：

`BookStoreErrorCode` 类是我们定义的与该业务子模块息息相关的错误码，举几个例子
```java
    /**
     * 虽然<strong>不推荐</strong>，但允许在模块中自定义新的错误码，而不去使用通用库中已经定义的 {@link CommonErrorCode#NOT_FOUND} 错误码
     */
    NOT_FOUND_BOOK("NotFoundBook", "Book {0} not found."),

    /**
     * 有如下两种定义错误码的思路：
     * 1. 定义宽泛的错误码，传入参数，如 Exists，传入 Book[id=1]
     * 2. 定义特定的错误码，如 InvalidBookId.Exists，不用传入参数
     * <p>
     * 具体采用哪种，可以根据喜好来决定，个人更偏向于定义相对宽泛的错误码，上面的 {@link #NOT_FOUND_BOOK} 示例也类似
     */
    EXISTS("Exists", "The specified object {0} already exists."),
    INVALID_BOOK_ID_EXISTS("InvalidBookId.Exists", "The specified bookId already exists.");

    BookStoreErrorCode(String code, String message) {
        this.code = code;
        this.message = message;
    }

    /**
     * Customized error code
     */
    private String code;
    /**
     * Error message details
     */
    private String message;

    @Override
    public String getCode() {
        return "BookStore." + code;
    }

    @Override
    public String getMessage() {
        return message;
    }    
```
很容易发现它与 `CommonErrorCode` 中定义的通用错误码的不同之处，那就是更偏向于具体业务了。此外还需要注意 `getCode` 方法的实现，在一个产品中，为与其他子业务模块区分，我们在不同的业务模块中，使用特定的模块名称作为错误码前缀。另外一个主要注意的就是如上代码注释中提及的，在业务模块中错误码定义是采用 *宽泛化* 还是 *特定化* 模式，这个因人而异，在本实践中，我们更倾向于使用 *宽泛化* 的模式。

`RestExceptionHandler` 就本示例代码中，就只是一个 `CustomizedBaseExceptionHandler` 的空子类了。
```java
@ControllerAdvice
@RestController
public class RestExceptionHandler extends CustomizedBaseExceptionHandler {
}
```
如果要为某个特定的异常添加处理逻辑，可以在该处理器类中实现，实现方式请参考 `ResponseEntityExceptionHandler` 和 `CustomizedBaseExceptionHandler`。

关于该业务模块，还有最后两点值得一提，那就是对于『Not Found』和 『参数校验』的处理方式。

『Not Found』，在 RESTful 风格的 API 中是一个很值得推敲的技巧点。在 RFC 规范定义了 HTTP 404 这个响应状态码，用于描述 "Not Found" 错误。在以模板视图为返回内容的 Web MVC 中，该状态码表示访问的视图资源未找到，说明访问路径有误。而在以无状态的资源未返回内容的接口风格中，除了访问路径有误这一种原因外，还可能路径虽然没有问题，但资源在服务器上不存在了。比如 `GET /books/1` 或者 `PUT /books/1` 以及 `/books/foobar` 虽然从形式上来看，这三种也都勉强可以归类为路径不存在，但其实前两者和第三个的本质上是不同的，前两者匹配的是路径 `/books/{id}`，这里只是代表 id 为 1 的资源在服务器上不存在了，而 `/books/foobar` 则是在服务器上根本未定义这样的一个资源路径。对于这种情况，我们认为一个好的处理方式是，把第三种当做 HTTP 404 处理，即客户端访问了错误的资源路径，而把路径模式正确而资源可能因为已删除或未添加等原因导致的资源未找到，对应到 HTTP 400 状态码上，认为是客户端只是请求参数有问题，以至于请求到了不存在的资源。Spring WebMVC 默认会把未定义 `RequestMapping` 的路径使用默认的映射器处理器处理，把它当做是对静态资源的请求，从而给出一个 404 的错误响应状态。我们在 application.properties 中通过设置 `spring.mvc.throw-exception-if-no-handler-found=true` 和 `spring.resources.add-mappings=false` 改变这一点，对于非 SpringBoot 项目，也可以在 WvbMvcConfigure 中配置该属性，具体请参考官方文档。

『参数校验』，Spring 使用 Hibernate Validator 处理参数校验，当校验失败时，会抛出 `MethodArgumentNotValid` 异常，该异常处理在 `ResponseEntityExceptionHandler` 中有默认实现，但由于报错信息太冗杂，不太好识别，所以在 `CustomizedBaseExceptionHandler` 我们重写了对该异常的处理逻辑。`ValidationConfig` 中可以对校验规则进行配置，本案例中我们通过设置 `failFast=true` 使校验在遇到第一个失败字段时立即抛出异常。

至此，我们已经大致将异常处理实践中涉及的几个重要的点，都介绍出来了。

具体的代码实现细节，请参考源码 [Demo Source Code][demo-source-code]


[demo-source-code]: https://github.com/hatakawas/blogdemo-errorhandle "Demo Source Code"
 

参考：
- [Twitter Response Codes](https://developer.twitter.com/en/docs/basics/response-codes.html) 
- [Twitter Ads Response Codes](https://developer.twitter.com/en/docs/ads/general/guides/response-codes)
- [Facebook Graph API Handling Errors](https://developers.facebook.com/docs/graph-api/using-graph-api/error-handling/)
- [阿里云服务器错误码](https://error-center.aliyun.com/status/product/Ecs?spm=5176.10421674.home.5.7d341mda1mdaIs)
- [Implementing Validation for RESTful Services with Spring Boot](http://www.springboottutorial.com/spring-boot-validation-for-rest-services)
- [Guide to Spring Boot REST API Error Handling](https://www.toptal.com/java/spring-boot-rest-api-error-handling)
