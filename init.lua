-- IDEの警告対策
---@diagnostic disable-next-line: undefined-global
local hs = hs

-- alertの設定
hs.alert.defaultStyle.textSize = 15
hs.alert.defaultStyle.radius = 0

-- 設定のリロード
hs.hotkey.bind({"cmd", "shift"}, "r", function()
    hs.reload()
end)

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

-- mediaへの認証用関数
---@diagnostic disable-next-line: lowercase-global
function mediaAuth ()
    -- .zshrc を読み込み、環境変数を出力
    local handle = io.popen("zsh -c 'source ~/.zshrc; echo \"$MEDIA_USERNAME,$MEDIA_PASSWORD\"'")

    -- io.popenのnilチェック
    if not handle then
        hs.alert.show("環境変数の読み込みに失敗しました")
        print("ERROR: io.popen failed")
        return
    end

    local result = handle:read("*a")
    handle:close()

    -- 改行とカンマで分割
    result = result:gsub("\n", "")  -- 改行除去
    local username, password = result:match("([^,]+),([^,]+)") -- 正規表現で値を取得

    -- 環境変数のチェック
    if not username or not password then
        hs.alert.show("環境変数が取得できませんでした")
        print("ERROR: username or password not parsed correctly")
        return
    end

    -- mediaへの認証を実行
    local output, status = hs.execute("curl -vL -H '\''Content-Type: application/x-www-form-urlencoded'\'' -d '\''origurl=http%3a%2f%2fwww%2egoogle%2ecom&username="..username.."&password="..password.."&ok=ログイン'\'' https://metro-cit.ac.jp:9998/forms/user_login 2>&1", true)
    print(output)
    hs.alert.defaultStyle.atScreenEdge = 1
    hs.alert.defaultStyle.textSize = 8
    hs.alert.show(output)
end

-- media認証の手動実行
hs.hotkey.bind({"cmd", "shift"}, "o", function ()
    hs.timer.doAfter(2, mediaAuth)
end)

-- wifiの監視の初期化
local wifiWatcher = nil

-- wifiが変わった時に実行する関数
---@diagnostic disable-next-line: lowercase-global
function ssidChanged()
    hs.timer.doAfter(3, mediaAuth)
end

-- wifiの監視
wifiWatcher = hs.wifi.watcher.new(ssidChanged)
wifiWatcher:start()

-- 選択中の文字を取得
hs.hotkey.bind({"cmd", "shift"}, "M", function ()
    -- 直前のクリップボード内容を保存
    local original = hs.pasteboard.getContents()

    -- Cmd + C を送信（選択中の文字列をコピー）
    hs.eventtap.keyStroke({"cmd"}, "c")

    -- 少し待ってから取得（コピー完了を待つ）
    hs.timer.doAfter(0,2, function()
        local selected = hs.pasteboard.getContents()
        hs.alert.show(selected)
        print(selected)

        -- クリップボードを元に戻す
        hs.pasteboard.setContents(original)
    end)
end)

-- bootstrapの実行
hs.hotkey.bind({"cmd", "shift"}, "k", function ()
    hs.alert.defaultStyle.textSize = 10
    hs.alert.defaultStyle.atScreenEdge = 1
    local output, status = hs.execute("~/dotfiles/bootstrap.sh", true)
    hs.alert.show(output)
end)