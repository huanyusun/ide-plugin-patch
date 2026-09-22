# ide-plugin-patch

一个 JetBrains 插件的私有维护 fork(Apache-2.0,上游归属见 [LICENSE](LICENSE))。

在原插件能力之上做了最小改动:

- **国内站自定义 host**:设置中选择国内站时,所有 API 请求经由 `URLUtils.leetcodecnProxy` 指定的自托管地址发出;国内站语义(中文内容、登录流程、GraphQL 变体)全部保持不变
- **Cookie 域适配**:Cookie 登录抓取时同时识别自定义 host 下的 cookie
- **剥离遥测**:不再向第三方错误上报服务发送任何数据

## 构建

```bash
./gradlew buildPlugin     # 产物: build/distributions/*.zip
./gradlew test            # 176 个测试
```

## 安装

IDEA / PyCharm:`Settings → Plugins → ⚙ → Install Plugin from Disk…`,选中 zip 后重启 IDE。

## 部署(可选)

`deploy/` 内含自托管反代的一键部署脚本(nginx:80 ACME + stream SNI 复用 + 域名重写),供自建后端时参考,域名与后端站点需自行替换。
