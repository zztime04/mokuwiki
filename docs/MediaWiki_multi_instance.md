# MediaWiki 多实例部署与扩展管理脚本方案


## 一、方案目标

1. **多实例可复用**
   * 公共脚本可在每位运维的 `~/mediawiki-scripts/` 仓库中通过 Git 同步使用。
2. **基础环境一次搭建**
   * 在 Debian 12 上安装 Apache2 + PHP-FPM + MariaDB 10.11 + APCu，配置好 FastCGI 转发。
3. **实例按需部署**
   * 每个 Wiki 实例独立数据库、独立根目录，配置文件集中管理。
4. **扩展双轨管理**
   * **标准化**：通过 `extensions.conf` + `02-manage-extensions.sh` 批量可审计安装。
   * **快速安装**：通过 `install-extension.sh <instance> <url|pkg> <extname>` 一次性安装。
5. **安全隔离 Composer**
   * 所有 Composer 操作切换至非 root 用户 `wiki-deploy`。
6. **自动化与审计**
   * 脚本与配置纳入 Git，改动走 Code Review；日志与回滚机制保障稳定。

## 二、前提条件

* **操作系统**：Debian 12
* **Web 服务器**：Apache2（上游 Nginx 已做 SSL/TLS 反代）
* **PHP**：8.x + PHP-FPM + FastCGI
* **数据库**：MariaDB 10.11
* **缓存**：APCu（本地内存）
* **Composer 用户**：`wiki-deploy`（非 root，用于扩展依赖安装）
* **存储**：单节点、本地磁盘

## 三、目录结构

```
~/mediawiki-scripts/
├── scripts/
│   ├── 00-base-setup.sh
│   ├── init-instance-config.sh
│   ├── init-extensions-config.sh
│   ├── 01-deploy-instance.sh
│   ├── 02-manage-extensions.sh
│   └── install-extension.sh
└── instances/
    ├── wiki1/
    │   ├── instance.conf
    │   └── extensions.conf
    └── wiki2/
```

以上目录展示脚本与配置的组织方式，其中 `scripts/` 存放所有运维脚本，`instances/` 目录按实例保存配置文件。

## 四、配置文件规范

### 4.1 `instance.conf`（YAML）

```yaml
INSTANCE_NAME: wiki1
WEBROOT: /var/www/html/wiki1
SCRIPT_PATH: /wiki1
MW_VERSION: 1.43.3
DB_NAME: wiki1_db
DB_USER: wiki1_user
DB_PASS: secret123
ADMIN_USER: kbadmin
ADMIN_PASS: kbPass@2025
ADMIN_EMAIL: admin@yourdomain.com
```

### 4.2 `extensions.conf`（YAML）

```yaml
COMPOSER_VENDOR_DIR: vendor
SHARED_EXTENSIONS:
  - name: VisualEditor
    type: composer
    source: mediawiki/visualeditor:*
EXTENSIONS:
  - name: SemanticMediaWiki
    type: composer
    source: semantic-media-wiki/semantic-media-wiki:~3.3
  - name: CustomSkin
    type: archive
    source: https://example.com/skins/CustomSkin-1.0.2.tar.gz
    version: 1.0.2
```

## 五、脚本概览

| 脚本 | 作用 |
| --- | --- |
| `00-base-setup.sh` | 安装 Apache、PHP-FPM、MariaDB 等基础环境 |
| `init-instance-config.sh` | 生成实例配置文件 |
| `init-extensions-config.sh` | 生成扩展配置文件 |
| `01-deploy-instance.sh` | 部署或重装指定实例 |
| `02-manage-extensions.sh` | 按 `extensions.conf` 批量管理扩展 |
| `install-extension.sh` | 单扩展快速安装 |

## 六、执行流程示例

```bash
# 初始化实例配置
bash ~/mediawiki-scripts/scripts/init-instance-config.sh --interactive

# 部署实例
sudo bash ~/mediawiki-scripts/scripts/01-deploy-instance.sh --instance wiki1

# 初始化扩展清单
bash ~/mediawiki-scripts/scripts/init-extensions-config.sh --instance wiki1

# 批量安装扩展
sudo bash ~/mediawiki-scripts/scripts/02-manage-extensions.sh --instance wiki1

# 快速安装单个扩展
sudo bash ~/mediawiki-scripts/scripts/install-extension.sh \
  wiki1 https://example.com/skins/CustomSkin-1.0.2.tar.gz CustomSkin
```

## 七、日志与回滚

* 所有脚本执行写入 `~/mediawiki-scripts/logs/<脚本名>.log`
* 失败时自动删除已创建的数据库、目录和 vhost，保证环境整洁

## 八、安全与审计

* Composer 操作使用 `wiki-deploy` 用户
* `instances/` 下的模板纳入 Git 管理，所有改动走 Pull Request
* 备份 `~/mediawiki-scripts/` 与 `/var/www/html/`

