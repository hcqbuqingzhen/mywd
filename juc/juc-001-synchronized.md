 ## juc-001-synchronized
 >在java最初的学习中我们都学习了多线程，也学习了synchronized和lock相关的知识，但是对于java的并发包一直没有系统的学习，juc作为crud仔在项目中用的并不多，但无奈面试一些高级岗位都爱问，也许高级岗位需要掌握此技能吧。为了不永远做个crud仔，还是要系统学习下。此系列是对juc学习过程的总结。

### 1. synchronized的作用
先来看一下普通多线程中出现的线程不安全的现象。  
设计100张票，三个线程去卖票，每个线程每次卖票需要减去一张
```java
package com.guide.juc;
//锁
public class Suo {
    public static void main(String[] args) {
        Ticket ticket=new Ticket();
        new Thread(()->{
            for (int i=1;i<100;i++){
                try {
                    ticket.sole();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }

        },"A").start();

        new Thread(()->{
            for (int i=1;i<100;i++){
                try {
                    ticket.sole();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"B").start();

        new Thread(()->{
            for (int i=1;i<100;i++){
                try {
                    ticket.sole();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        },"C").start();
    }
}
class Ticket{
    //属性方法
    private int num=100;
    public  void sole() throws InterruptedException {
        if(num >0){
            if(num==1){
                //当一个线程耗时太多，cpu切到其他线程时，会导致线程不安全，出现前后数据不一致的问题。
                //加上synchronized时线程为安全的
                Thread.sleep(1000l); //1
            }
            System.out.println(Thread.currentThread().getName()+
                    "-卖了:"+(100-(--num))+"剩余："+num);
        }
    }
}
```

当运行此代码的时候，会出现最后的票的数量为-2,即出现超卖的现象。这是因为当num为1,某个线程sleep时(可以理解为一段长时间运行的代码)，另外两个线程进入方法执行，此时num>0因此会判断继续减一，出现线程不安全现象。  
当我们对方法增加synchronized关键字时，则为正常数据。


