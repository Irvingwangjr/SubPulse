# SubPulse 海外 App Store 上架操作清单

按以下顺序操作，可在不办国内 ICP 备案、不折腾欧盟 DSA 地址的情况下，以最短路径跑通海外上架 + StoreKit 2 订阅闭环。

---

## 第 1 步：本地运行与沙盒测试（今天就能完成）

1. 用 **Xcode 16+** 打开 `SubPulse.xcodeproj`。
2. 选一台 iOS 17+ 模拟器（如 iPhone 16），按 **⌘R** 运行。
3. 验证完整功能：
   - 概览页自动汇总多币种月/年支出；
   - 订阅页新增、编辑、左滑删除、右滑标记“已续费”；
   - 当订阅达到 5 个时自动触发 Paywall；
   - 在 Paywall 页点 **Continue** 测试 StoreKit 2 订阅购买（已自动绑定 `SubPulse.storekit`，无需联网或配置苹果后台）；
   - 在 Xcode 菜单 **Debug → StoreKit → Manage Transactions** 可查看/退款/重置沙盒订阅，测试 **Restore Purchases**。

---

## 第 2 步：替换为你的专属配置

1. **App 图标**：已完成（1024×1024 无透明通道 PNG 已放入 `SubPulse/Assets.xcassets/AppIcon.appiconset/AppIcon.png`，可随时替换）。
2. **Bundle ID 与签名**：
   - 在 Xcode 左侧选中 `SubPulse` 工程 → `TARGETS` → `SubPulse` → **Signing & Capabilities**；
   - 选择你的 **Team**（Apple Developer 账号）；
   - `Bundle Identifier` 已预配为 `com.irvingwangjr.subpulse`（如需更换可在此修改）。
3. **托管隐私政策与条款网页**：
   - 修改 `docs/index.html`、`docs/privacy.html`、`docs/terms.html` 中的邮箱 `support@subpulse.example.com` 为你的真实支持邮箱；
   - GitHub Pages 已开启：`https://irvingwangjr.github.io/SubPulse/`，且已回填到 `SubPulse/Models/AppConfig.swift`。

---

## 第 3 步：App Store Connect 配置（海外最短路径）

1. **协议、税务与银行业务**：
   - 签署 **Paid Applications Agreement**；
   - 填写美国税表 **W-8BEN**（个人）或 **W-8BEN-E**（企业），避免美国区收入被预扣 30%；
   - 绑定收款银行卡；
   - 申请 **App Store Small Business Program**（年收入 100 万美元以下抽成从 30% 降至 **15%**）。
2. **创建 App**：
   - 平台选 iOS，主语言选 **English (U.S.)**，Bundle ID 与 Xcode 保持一致。
3. **定价与销售范围**：
   - 价格选 **Free**；
   - 销售地区先勾选 **United States, Canada, United Kingdom, Australia, Japan, Singapore** 等；
   - **暂不勾选 China mainland**（免国内 ICP 备案）和 **欧盟成员国**（免 DSA 公开个人地址/电话）。
4. **配置自动续期订阅（关键！ID 必须与代码一致）**：
   - 在 App Store Connect → **Subscriptions** 创建订阅组 `SubPulse Pro`；
   - 新建两个订阅产品：
     - Product ID：`com.irvingwangjr.subpulse.pro.monthly`（1 Month，建议 $2.99）
     - Product ID：`com.irvingwangjr.subpulse.pro.yearly`（1 Year，建议 $19.99，可配 7-Day Free Trial Introductory Offer）
   - 为每个订阅填写英文显示名称和描述，并上传一张 Paywall 审核截图；
   - **注意**：首次提审时必须在 App 版本页面下方勾选关联这两个内购产品一起提交审核！
5. **App 隐私（Privacy Nutrition Label）**：
   - 直接选择 **No, we do not collect data from this app**（本应用 100% 本地存储，无任何数据上传）。

---

## 第 4 步：打包上传与提审

1. 在 Xcode 顶部设备选 **Any iOS Device (arm64)** → 菜单 **Product → Archive** → **Distribute App → App Store Connect**。
2. 准备截图（6.9" / 6.7" iPhone 模拟器直接 **⌘S** 截 4–5 张核心界面图：Overview、Subscriptions、Upcoming、Paywall）。
3. 填写审核备注（**App Review Information → Notes**），可直接复制：
   > SubPulse is a 100% on-device subscription tracker and does not require login or an account. On first launch, 4 sample subscriptions are pre-loaded so you can immediately test the multi-currency overview, upcoming reminders, and swipe-to-renew features. To test the Pro subscription paywall, tap the "Pro" button in the top-right corner of Overview or go to Settings → Upgrade to SubPulse Pro.
4. 发布方式先选 **Manually release this version**，审核通过后自己点发布。

---

## 第 5 步：后续版本自动化发布（二选一）

首次建 App、填税表、配内购是**一次性手动操作**；之后所有版本迭代都可以做到**打一个 tag 自动打包上传 TestFlight / App Store**：

### 方案 A：Apple Xcode Cloud（最省心，免配证书）
- 苹果官方自带 CI/CD，Apple Developer 账号**每月免费送 25 小时构建时长**；
- 在 Xcode 左侧打开 Cloud 标签页 → 关联本 GitHub 仓库 → 绑定 `main` 分支或 `v*` tag → 勾选自动发 TestFlight / App Store，证书和签名由苹果全自动托管。

### 方案 B：GitHub Actions + Fastlane（仓库已预置好脚本）
本仓库已包含 `fastlane/Fastfile` 和 `.github/workflows/ios-release.yml`。只需在 GitHub 仓库 **Settings → Secrets and variables → Actions** 配置一次以下密钥：
- `APP_IDENTIFIER`（Repository Variable）：你的正式 Bundle ID
- `APPLE_TEAM_ID`：Apple Developer Team ID
- `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_CONTENT`（Base64 编码的 `.p8` 文件）：在 App Store Connect → Users and Access → Integrations → App Store Connect API 创建，免 2FA 登录
- `MATCH_GIT_URL` / `MATCH_PASSWORD`：用于 `fastlane match` 托管加密签名证书的私有仓库与密码

配置完之后：
- 推一个 tag（如 `git tag v1.0.1 && git push --tags`）自动构建并上传 TestFlight；
- 在 GitHub Actions 手动点 **Run workflow** 选 `release`（可勾选 `submit_for_review`）即可自动打包上传并提审。

