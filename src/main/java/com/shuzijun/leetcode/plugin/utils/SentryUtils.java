package com.shuzijun.leetcode.plugin.utils;

/**
 * fork 版:遥测已剥离。保留方法签名以兼容调用方,不再向 sentry.io 上报任何错误或配置信息。
 *
 * @author shuzijun
 */
public class SentryUtils {

    public static void submitErrorReport(Throwable error, String description) {
        // no-op
    }
}
