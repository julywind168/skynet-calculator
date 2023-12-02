# skynet-calculator
Parallel computing framework, powered by skynet

该框架将更改以往的 skynet 开发体验. 游戏的状态和逻辑全部由框架托管, 相当于一个黑箱, 你只需要对其发出 action.
action 之间是否并发执行, 根据 action 的读写锁决定 (由开发人员定义)

读写锁一般根据要读写的 storage 节点来命名: 

    "*" : 锁住所有

    "" :  无锁

    "usermgr.usermap.#uid, roommap.#rid" : 定义了2个锁, #uid = {params.uid}


注意1. 子仓库 [skynet](https://github.com/HYbutterfly/skynet/tree/lua) 是一个修改版 

注意2. worker 共享状态 storage 基于共享table指针实现, 这是一个魔法,安全性有待验证


# Build
```
    git clone https://github.com/HYbutterfly/skynet-calculator.git
    cd skynet-calculator

    git submodule update --init
    cd skynet
    make 'PLATFORM' # PLATFORM can be linux, macosx, freebsd now
    cd ..
    make 'PLATFORM'
```

# Test
```
    chmod +x start.sh
    ./start
```