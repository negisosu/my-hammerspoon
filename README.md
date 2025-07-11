# いろいろ自動化するためのHammerspoon!

## Hammerspoonとは

macOS用の自動化ツール。luaスクリプトとOSを繋げてくれるツールです。

## 使い方

まずはHammerspoonをインストール

```
brew install hammerspoon --cask
```

コンフィグを書くためのディレクトリを用意

```
mkdir ~/.hammerspoon
```

コンフィグを書くファイルを作成

```
touch ~/.hammerspoon/init.lua
```

あとは書くだけ！自動リロードはあると便利なのでよかったらこれだけでも追加しといてください！

```
-- init.lua の自動リロード
local function reloadConfig(files)
    for _, file in pairs(files) do
        if file:match("init%.lua$") then
            hs.reload()
            return
        end
    end
end

-- configの監視
local configFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
configFileWatcher:start()
```

## 今使ってる自動化

### 自動リロード

基本的に`~/.hammerspoon/init.lua`に自動化のコンフィグを書くため、`~/.hammerspoon/`内のファイル変更を検知して、自動で`hs.reload()`を実行してくれるようにしてる。

手動実行のために`⌘⇧R`でもリロード実行できるようにしている。

### 学校WIFIへの自動接続

学校のWIFIを利用する時に認証が必要だが、認証ページを開くまでにものすごく時間がかかったり、場所によっては全くページが開けないことがあるため、自身の環境から直でPOSTして認証を行うために実装。

`~/.zshrc`に`export MEDIA_USERNAME="username"`と`export MEDIA_PASSWORD="password"`を記述していれば繋いだ時にログイン。

繋いだ時に関数が実行されない時ように`⌘⇧O`でも実行可能。

## 今後追加したい自動化

コピペとかみたいに選択している範囲を何かしらのAPI（Notionとか）に繋いで、記録できるようにする。今の所`⌘⇧M`で選択範囲の取得はできてる。
