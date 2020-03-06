マルチテナント化（分離されたスキーマを持つ共有データベース）
====

Building Multi Tenant Applications with Django
https://books.agiliq.com/projects/django-multi-tenant/en/latest/index.html

## サブドメインの割振り
サブドメイン(co*.profile.local)によってスキーマを変化させる.

```
# server/settings.py

ALLOWED_HOSTS = ['profile.local', '.profile.local']

# rest apiを使用する場合
CORS_ORIGIN_WHITELIST = (
    # ...
    'http://profile.local:8080',
    'http://co1.profile.local:8080',
    'http://co2.profile.local:8080',
    'http://co3.profile.local:8080',
    'http://co4.profile.local:8080',
    'http://co5.profile.local:8080',
    # ...
)

# テナントのドメインとスキーマ名の対応
TENANTS_MAP = {
    "co1.profile.local": "alfa",
    "co2.profile.local": "bravo",
    "co3.profile.local": "charlie",
    "co4.profile.local": "delta",
    "co5.profile.local": "echo",
}
```

テスト用にhosts追加
```
# C:\Windows\System32\Drivers\etc\hosts
127.0.0.1 profile.local
127.0.0.1 co1.profile.local
127.0.0.1 co2.profile.local
127.0.0.1 co3.profile.local
127.0.0.1 co4.profile.local
127.0.0.1 co5.profile.local
```

## マイグレーション

マイグレーションコマンドの拡張.

```
# profile/management/commands/migrate_schemas.py
from django.core.management.commands.migrate import Command as MigrationCommand

from django.db import connection
from ....server.settings import TENANTS_MAP

class Command(MigrationCommand):
    '''
    Postgres用テナント版マイグレーションコマンド
    '''
    def handle(self, *args, **options):
        with connection.cursor() as cursor:
            schemas = TENANTS_MAP.values()
            for schema in schemas:
                cursor.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
                cursor.execute(f"SET search_path to {schema}")
                super(Command, self).handle(*args, **options)
```

* `CREATE SCHEMA IF NOT EXISTS {schema}` TENANTS_MAPにて定義したスキーマ名で新しいスキーマを作成する.
* `SET search_path to {schema}` 指定されたスキーマを使用するように接続を設定する.

`manage.py migrate_schemas`にてスキーマを作成してテナントに移行する。

## スキーマ取得用ユーティリティの作成
スキーマ取得・設定用のユーティリティメソッド作成`tenants.py`

```
# profile/tenants.py
from django.db import connection
from ..server.settings import TENANTS_MAP

def hostname_from_request(request):
    # split on `:` to remove port
    return request.get_host().split(':')[0].lower()

def tenant_schema_from_request(request):
    hostname = hostname_from_request(request)
    return TENANTS_MAP.get(hostname)

def set_tenant_schema_for_request(request):
    schema = tenant_schema_from_request(request)
    with connection.cursor() as cursor:
        cursor.execute(f"SET search_path to {schema}")
```

## スキーマを設定するミドルウェア
`request` `respons`にて自動で`set_tenant_schema_for_request`が実行されるように、
ミドルウェアを作成する.

```
# profile/middlewares.py
from .tenants import set_tenant_schema_for_request

class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        set_tenant_schema_for_request(request)
        response = self.get_response(request)
        return response
```

```
# server/settings.py
MIDDLEWARE = [
    # ...
    'profile.middlewares.TenantMiddleware',
]
```

## manage.pyの拡張
`manage.py`ではミドルウェアが機能しない為、
コマンドでスキーマを使用できるように新しい`manage.py`を作成する。

```
#!/usr/bin/env python
"""
Django's command-line utility for administrative tasks.
スキーマ分離によるテナント版.
第一引数にスキーマを指定すること.
ex: python tenant_context_manage.py alfa createsuperuser
"""
import os
import sys


def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'server.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    from django.db import connection
    args = sys.argv
    schema = args[1]
    with connection.cursor() as cursor:

        cursor.execute(f"SET search_path to {schema}")
        del args[1]

        execute_from_command_line(args)


if __name__ == '__main__':
    main()
```


## 共有スキーマ（没）
### マルチテナント用モデルの作成
`Tenant`モデルを作成.
```
# profile/models.py
class Tenant(models.Model):
    name = models.CharField(max_length=100)
    subdomain_prefix = models.CharField(max_length=100, unique=True)
```

`TenantAwareModel`を作成.
今後モデルのサブクラスは`model.Model`ではなく`TenantAwareModel`を使う.
```
# profile/models.py
class TenantAwareModel(models.Model):
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)

    class Meta:
        abstract = True
```

マルチテナント用モデルは全て`tenants/models.py`に記載.
```
# profile/models.py
class User(TenantAwareModel,AbstractUser):
    #...

class Department(TenantAwareModel):
    #...

```

### テナントの識別
#### 各テナントにサブドメインを与える
```
# profile/utils.py
from .models import Tenant

def hostname_from_request(request):
    # split on `:` to remove port
    return request.get_host().split(':')[0].lower()

def tenant_from_request(request):
    hostname = hostname_from_request(request)
    subdomain_prefix = hostname.split('.')[0]
    return Tenant.objects.filter(subdomain_prefix=subdomain_prefix).first()
```

テスト用にhosts追加
```
# C:\Windows\System32\Drivers\etc\hosts
127.0.0.1 profile.local
127.0.0.1 co01.profile.local
127.0.0.1 co02.profile.local
```

`settings.py`の`ALLOWED_HOSTS`とREST用の`CORS_ORIGIN_WHITELIST`にもサブドメイン追加.
