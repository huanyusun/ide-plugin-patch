package com.shuzijun.leetcode.plugin.utils;

import com.shuzijun.leetcode.plugin.model.Config;
import com.shuzijun.leetcode.plugin.setting.PersistentConfig;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

public class URLUtilsTest {

    @Before
    public void setUp() {
        System.setProperty("leetcode.test.base.url", "http://127.0.0.1:8080/");
    }

    @After
    public void tearDown() {
        System.clearProperty("leetcode.test.base.url");
        PersistentConfig.getInstance().setInitConfig(null);
    }

    @Test
    public void buildsAllExternalQuestionAndAccountUrlsFromTheTestEndpoint() {
        assertEquals("http://127.0.0.1:8080", URLUtils.getLeetcodeUrl());
        assertEquals("http://127.0.0.1:8080/problems/two-sum",
                URLUtils.getLeetcodeProblems() + "two-sum");
        assertEquals("http://127.0.0.1:8080/accounts/login/", URLUtils.getLeetcodeLogin());
        assertEquals("http://127.0.0.1:8080/accounts/logout/", URLUtils.getLeetcodeLogout());
        assertEquals("http://127.0.0.1:8080/points/api/", URLUtils.getLeetcodePoints());
        assertEquals("http://127.0.0.1:8080/submissions/detail/123/check/",
                URLUtils.getLeetcodeSubmissions() + "123/check/");
    }

    @Test
    public void routesCnSelectionThroughPrivateProxyWhileKeepingCnSemantics() {
        System.clearProperty("leetcode.test.base.url");
        Config config = new Config();
        config.setUrl(URLUtils.leetcodecn);
        PersistentConfig.getInstance().setInitConfig(config);

        assertEquals(URLUtils.leetcodecnProxy, URLUtils.getLeetcodeHost());
        assertEquals("https://" + URLUtils.leetcodecnProxy, URLUtils.getLeetcodeUrl());
        assertEquals("https://" + URLUtils.leetcodecnProxy + "/graphql", URLUtils.getLeetcodeGraphql());
        assertEquals("https://" + URLUtils.leetcodecnProxy + "/problems/two-sum",
                URLUtils.getLeetcodeProblems() + "two-sum");
        assertTrue(URLUtils.isCn());
        assertTrue(URLUtils.equalsHost(URLUtils.leetcodecn));
        assertTrue(URLUtils.equalsHost(URLUtils.leetcodecnOld));
        assertFalse(URLUtils.equalsHost(URLUtils.leetcode));
    }

    @Test
    public void keepsInternationalSelectionUntouched() {
        System.clearProperty("leetcode.test.base.url");
        Config config = new Config();
        config.setUrl(URLUtils.leetcode);
        PersistentConfig.getInstance().setInitConfig(config);

        assertEquals(URLUtils.leetcode, URLUtils.getLeetcodeHost());
        assertFalse(URLUtils.isCn());
        assertTrue(URLUtils.equalsHost(URLUtils.leetcode));
    }

    @Test
    public void treatsManuallyEnteredProxyHostAsCnSelection() {
        System.clearProperty("leetcode.test.base.url");
        Config config = new Config();
        config.setUrl(URLUtils.leetcodecnProxy);
        PersistentConfig.getInstance().setInitConfig(config);

        assertEquals(URLUtils.leetcodecnProxy, URLUtils.getLeetcodeHost());
        assertTrue(URLUtils.isCn());
        assertTrue(URLUtils.equalsHost(URLUtils.leetcodecn));
    }
}
