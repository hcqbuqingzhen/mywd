---
title: redis分布式锁和redisoon实现
date: 2022-06-05 17:36:13
tags: java
---
# redis分布式锁和redisoon实现
>之前的项目中有一个需求,向微信请求获取小程序二维码,需要一个key,这个key需要拿着开发者id和密钥获取,有效期7200秒.这个key存储到redis中,过期后再去微信访问获取.
>我想如果使用redis的setnx可以解决这个问题.但是可能会出现多个服务请求获取不到,然后都去调用微信的接口去拿,这样又会导致新的存储的key失效.
>还是得让这个获取-设置的操作成为原子性的,但使用lua脚本似乎也不能解决问题,因为中间需要调用微信的接口.
>所以还得是使用分布式锁

[![XaXhDI.png](https://s1.ax1x.com/2022/06/04/XaXhDI.png)](https://imgtu.com/i/XaXhDI)
## 分布式锁设计
>分布式锁有几种实现,自己使用redis简单的实现.使用redisson的实现,zk的实现.
>这种可以采用适配器模式来实现

- DistributedLock
```java
/**
 * 锁对象
 * DistributedLock提供对不同分布式锁的包装,会有redis实现和zk实现,DistributedLock将第三方的实现返回的锁包装.提供对外统一的形式.
 */
@NoArgsConstructor
@AllArgsConstructor
@Data
public class DistributedLock {
    private String key;
    private long waitTime;
    private long leaseTime;
    private  TimeUnit unit;
    private boolean isFair;
    /**
     * 具体实现类
     */
    private  DistributedLockAdapter locker;

    public boolean tryLock() throws Exception{
        return locker.tryLock(key,waitTime,leaseTime,unit,isFair);
    }

    public void lock() throws Exception{
        locker.lock(key,waitTime,leaseTime,unit,isFair);
    }

    public void unlock() {
        locker.unlock();
    }


}
```
- DistributedLockAdapter

```java
/**
 * 分布式锁具体实现
 */
public interface DistributedLockAdapter {
    /**
     * 尝试加锁
     * @param key
     * @param waitTime
     * @param leaseTime
     * @param unit
     */
    boolean tryLock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair) throws InterruptedException;

    /**
     * 枷锁
     * @param key
     * @param waitTime
     * @param leaseTime
     * @param unit
     * @param isFair
     */
    void lock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair);

    /**
     * 解锁
     */
    void unlock() ;
}
```

- RedissonDistributedLockAdapter
```java
public class RedissonDistributedLockAdapter implements DistributedLockAdapter {
    private static RedissonClient redisson=Redisson.create();

    private RLock rLock;

    private void getLock(String key, boolean isFair) {
        if(Objects.nonNull(rLock)){
            return;
        }
        if (isFair) {
            rLock = redisson.getFairLock(CommonConstant.LOCK_KEY_PREFIX + ":" + key);
        } else {
            rLock =  redisson.getLock(CommonConstant.LOCK_KEY_PREFIX + ":" + key);
        }
    }
    @Override
    public boolean tryLock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair) throws InterruptedException {
        getLock(key,isFair);
        return rLock.tryLock(waitTime, leaseTime, unit);
    }

    @Override
    public void lock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair) {
        getLock(key,isFair);
        rLock.lock(leaseTime,unit);
    }

    @Override
    public void unlock() {
        if(Objects.nonNull(rLock)){
            if (rLock.isLocked()) {
                rLock.unlock();
            }
        }
    }
}
```
- RedisDistributedLockFactory

```java
**
 * 获取redis分布式锁
 */
public class RedisDistributedLockFactory {
    public static DistributedLock getDistributedLock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair){
        return new DistributedLock(key,waitTime,leaseTime,unit,isFair,new RedissonDistributedLockAdapter());
    }
}
```

## 不使用redisson自己使用redis实现
- RedisDistributedLock

```java
@Slf4j
@ConditionalOnClass(RedisTemplate.class)
@Deprecated
public class RedisDistributedLock {
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    private ThreadLocal<String> lockFlag = new ThreadLocal<>();

    private static final String UNLOCK_LUA;

    /*
     * 通过lua脚本释放锁,来达到释放锁的原子操作
     */
    static {
        UNLOCK_LUA = "if redis.call(\"get\",KEYS[1]) == ARGV[1] " +
                "then " +
                "    return redis.call(\"del\",KEYS[1]) " +
                "else " +
                "    return 0 " +
                "end ";
    }

    public RedisDistributedLock(RedisTemplate<String, Object> redisTemplate) {
        super();
        this.redisTemplate = redisTemplate;
    }

    /**
     * 获取锁
     *
     * @param key 锁的key
     * @param expire 获取锁超时时间
     * @param retryTimes 重试次数
     * @param sleepMillis 获取锁失败的重试间隔
     * @return 成功/失败
     */
    public boolean lock(String key, long expire, int retryTimes, long sleepMillis) {
        boolean result = setRedis(key, expire);
        // 如果获取锁失败，按照传入的重试次数进行重试
        while ((!result) && retryTimes-- > 0) {
            try {
                log.debug("get redisDistributeLock failed, retrying..." + retryTimes);
                Thread.sleep(sleepMillis);
            } catch (InterruptedException e) {
                log.warn("Interrupted!", e);
                Thread.currentThread().interrupt();
            }
            result = setRedis(key, expire);
        }
        return result;
    }

    private boolean setRedis(final String key, final long expire) {
        try {
            boolean status = redisTemplate.execute((RedisCallback<Boolean>) connection -> {
                String uuid = UUID.randomUUID().toString();
                lockFlag.set(uuid);
                byte[] keyByte = redisTemplate.getStringSerializer().serialize(key);
                byte[] uuidByte = redisTemplate.getStringSerializer().serialize(uuid);
                boolean result = connection.set(keyByte, uuidByte, Expiration.from(expire, TimeUnit.MILLISECONDS), RedisStringCommands.SetOption.ifAbsent());
                return result;
            });
            return status;
        } catch (Exception e) {
            log.error("set redisDistributeLock occured an exception", e);
        }
        return false;
    }

    /**
     * 释放锁
     * @param key 锁的key
     * @return 成功/失败
     */
    public boolean releaseLock(String key) {
        // 释放锁的时候，有可能因为持锁之后方法执行时间大于锁的有效期，此时有可能已经被另外一个线程持有锁，所以不能直接删除
        try {
            // 使用lua脚本删除redis中匹配value的key，可以避免由于方法执行时间过长而redis锁自动过期失效的时候误删其他线程的锁
            // spring自带的执行脚本方法中，集群模式直接抛出不支持执行脚本的异常，所以只能拿到原redis的connection来执行脚本
            Boolean result = redisTemplate.execute((RedisCallback<Boolean>) connection -> {
                byte[] scriptByte = redisTemplate.getStringSerializer().serialize(UNLOCK_LUA);
                return connection.eval(scriptByte,  ReturnType.BOOLEAN, 1
                        , redisTemplate.getStringSerializer().serialize(key)
                        , redisTemplate.getStringSerializer().serialize(lockFlag.get()));
            });
            return result;
        } catch (Exception e) {
            log.error("release redisDistributeLock occured an exception", e);
        } finally {
            lockFlag.remove();
        }
        return false;
    }
}
```

## 使用zk实现

- ZookeeperDistributedLock

```java
@AllArgsConstructor
@NoArgsConstructor
public class ZookeeperDistributedLock implements DistributedLockAdapter {
    public ZookeeperDistributedLock(CuratorFramework client){
        this.client=client;
    }
    private CuratorFramework client;
    private InterProcessMutex lock;

    private void getLock(String key) {
        if(Objects.isNull(lock)){
            InterProcessMutex lock = new InterProcessMutex(client, getPath(key));
        }
    }
    @Override
    public boolean tryLock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair) throws Exception {
        getLock(key);
        if(lock.acquire(waitTime,unit)){
            return true;
        }
        return false;
    }

    @Override
    public void lock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair) throws Exception {
        lock.acquire();
    }

    @Override
    public void unlock() throws Exception {
        if (lock.isAcquiredInThisProcess()) {
            lock.release();
        }
    }

    private String getPath(String key) {
        return CommonConstant.PATH_SPLIT + CommonConstant.LOCK_KEY_PREFIX + CommonConstant.PATH_SPLIT + key;
    }
}

```

- ZookeeperDistributedLockFactory

```java
@Component
@ConditionalOnProperty(prefix = "rrs.lock", name = "lockerType", havingValue = "ZK")
public class ZookeeperDistributedLockFactory {
    @Autowired
    private static CuratorFramework client;

    public DistributedLock getLock(String key, long waitTime, long leaseTime, TimeUnit unit, boolean isFair){
        ZookeeperDistributedLock Locker=new ZookeeperDistributedLock(client);
        return new DistributedLock(key,waitTime,leaseTime,unit,isFair, Locker);
    }
}
```

## 小结

- 如果我们自己使用setnx 也可以实现简单的分布式锁. 但有以下几个缺点 不具备可重入性,不支持续约,不具备阻塞的能力
- Redisson的分布式锁在满足以上三个基本要求的同时还增加了线程安全的特点。利用Redis的Hash结构作为储存单元，将业务指定的名称作为key，将随机UUID和线程ID作为field，最后将加锁的次数作为value来储存.
- Redisson的可重入锁解决了setnx锁的许多先天性不足，但是由于它仍然是以单一一个key的方式储存在固定的一个Redis节点里，并且有自动失效期。
- redis作者Salvatore提出了一个基于多个节点的高可用分布式锁的算法，起名叫红锁RedLock。
- 虽然Redlock的算法提供了高可用的特性，但建立在大多数可见原则的前提下，这样的算法适用性仍然有一定局限。Redisson为此提供了基于增强型的算法的高可用分布式联锁RedissonMultiLock。这种算法要求客户端必须成功获取全部节点的锁才被视为加锁成功，从而更进一步提高了算法的可靠性。

