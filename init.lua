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
    hs.alert.defaultStyle.fadeOutDuration = 5
    hs.alert.show(output)
end

-- media認証の手動実行
hs.hotkey.bind({"cmd", "shift"}, "o", function ()
    hs.timer.doAfter(2, mediaAuth)
end)

-- bootstrapの実行
hs.hotkey.bind({"cmd", "shift"}, "k", function ()
    hs.alert.defaultStyle.textSize = 10
    hs.alert.defaultStyle.atScreenEdge = 1
    local output = hs.execute("sudo ~/dotfiles/bootstrap.sh")
    hs.alert.show(output)
    print(output)

end)

-- 選択中の文字をNotionページに追記する関数
---@diagnostic disable-next-line: lowercase-global
function appendToNotionPage(text)
    -- .zshenv を読み込み、環境変数を出力
    local handle = io.popen("zsh -c 'source ~/.zshenv; echo \"$NOTION_TOKEN\"'")
    if not handle then
        hs.alert.show("環境変数の読み込みに失敗しました")
        print("ERROR: io.popen failed")
        return
    end
    local result = handle:read("*a")
    handle:close()
    result = result:gsub("\n", "")
    local notion_token = result:match("([^,]+)")
    if not notion_token then
        hs.alert.show("Notionのトークンが設定されていません")
        return
    end

    -- 最後に開いたページを取得する
    local page_data = hs.json.encode({
        ["sort"] = {
            ["direction"] = "descending",
            ["timestamp"] = "last_edited_time"
        },
        ["page_size"] = 1
    })

    local page_url = "https://api.notion.com/v1/search"

    local page_safe_data = page_data:gsub("'", "'\\''")

    local page_cmd = string.format(
        "curl -s -X POST '%s' -H 'Authorization: Bearer %s' -H 'Content-Type: application/json' -H 'Notion-Version: 2022-06-28' -d '%s'",
        page_url, notion_token, page_safe_data
    )

    local json_str = hs.execute(page_cmd)

    local page_table = hs.json.decode(json_str)

    local page_id = page_table.results[1].id

    -- hs.json.encodeで安全にJSONを作成
    local data = hs.json.encode({
        children = {
            {
                ["type"] = "code",
                ["object"] = "block",
                ["code"] = {
                    ["rich_text"] = {
                        {
                            ["type"] = "text",
                            ["text"] = {
                                ["content"] = text
                            }
                        }
                    },
                    ["language"] = "typescript",
                    ["caption"] = {

                    }
                }
              }
        }
    })

    local url = "https://api.notion.com/v1/blocks/" .. page_id .. "/children"
    -- シングルクォート内のシングルクォートをエスケープ
    local safe_data = data:gsub("'", "'\\''")
    local cmd = string.format(
        "curl -s -X PATCH '%s' -H 'Authorization: Bearer %s' -H 'Content-Type: application/json' -H 'Notion-Version: 2022-06-28' -d '%s'",
        url, notion_token, safe_data
    )
    local output = hs.execute(cmd)
    print(output)
    if output:find('"object":"error"') then
        hs.alert.show("Notionへの追加に失敗しました")
    else
        hs.alert.show("Notionに追加しました")
    end
end

-- 選択中の文字を取得
hs.hotkey.bind({"cmd", "shift"}, "M", function ()
    -- 直前のクリップボード内容を保存
    local original = hs.pasteboard.getContents()

    -- Cmd + C を送信（選択中の文字列をコピー）
    hs.eventtap.keyStroke({"cmd"}, "c")

    -- 少し待ってから取得（コピー完了を待つ）
    hs.timer.doAfter(0.2, function()
        local selected = hs.pasteboard.getContents()
        -- Notionに追加
        appendToNotionPage(selected)
        -- クリップボードを元に戻す
        hs.pasteboard.setContents(original)
    end)
end)

-- Notionのテーブル（データベース）にテキストを追加する関数
---@diagnostic disable-next-line: lowercase-global
function addTextToNotionDatabase(text)
    -- .zshenv を読み込み、環境変数を出力
    local handle = io.popen("zsh -c 'source ~/.zshenv; echo \"$NOTION_TOKEN\"'")
    if not handle then
        hs.alert.show("環境変数の読み込みに失敗しました")
        print("ERROR: io.popen failed")
        return
    end
    local result = handle:read("*a")
    handle:close()
    result = result:gsub("\n", "")
    local notion_token = result:match("([^,]+)")
    if not notion_token then
        hs.alert.show("Notionのトークンが設定されていません")
        return
    end

    -- 翻訳APIのエンドポイント
    local url = "https://libretranslate.com/translate"

    -- リクエストボディ


    local translated = ""

    -- HTTPリクエスト送信
    local translate_cmd = string.format(
        "curl -X POST http://localhost:5000/translate -d q=%s -d source=en -d target=ja",
        text
    )

    local translate_str = hs.execute(translate_cmd)

    print(translate_str)

    -- 最後に開いたページを取得する
    local page_data = hs.json.encode({
        ["sort"] = {
            ["direction"] = "descending",
            ["timestamp"] = "last_edited_time"
        },
        ["page_size"] = 1
    })

    local page_url = "https://api.notion.com/v1/search"

    local page_safe_data = page_data:gsub("'", "'\\''")

    local page_cmd = string.format(
        "curl -s -X POST '%s' -H 'Authorization: Bearer %s' -H 'Content-Type: application/json' -H 'Notion-Version: 2022-06-28' -d '%s'",
        page_url, notion_token, page_safe_data
    )

    local json_str = hs.execute(page_cmd)

    local page_table = hs.json.decode(json_str)

    local page_id = page_table.results[1].id

    -- hs.json.encodeで安全にJSONを作成
    local data = hs.json.encode({
        children = {
            {
                ["type"] = "text",
                ["object"] = "block",
                ["text"] = {
                    ["content"] = text
                }
              }
        }
    })

    local url = "https://api.notion.com/v1/blocks/" .. page_id .. "/children"
    -- シングルクォート内のシングルクォートをエスケープ
    local safe_data = data:gsub("'", "'\\''")
    local cmd = string.format(
        "curl -s -X PATCH '%s' -H 'Authorization: Bearer %s' -H 'Content-Type: application/json' -H 'Notion-Version: 2022-06-28' -d '%s'",
        url, notion_token, safe_data
    )
    local output = hs.execute(cmd)
    print(output)
    if output:find('"object":"error"') then
        hs.alert.show("Notionへの追加に失敗しました")
    else
        hs.alert.show("Notionに追加しました")
    end
end

-- 選択中の文字を取得
hs.hotkey.bind({"cmd", "shift"}, ",", function ()
    -- 直前のクリップボード内容を保存
    local original = hs.pasteboard.getContents()

    -- Cmd + C を送信（選択中の文字列をコピー）
    hs.eventtap.keyStroke({"cmd"}, "c")

    -- 少し待ってから取得（コピー完了を待つ）
    hs.timer.doAfter(0.2, function()
        local selected = hs.pasteboard.getContents()
        -- Notionに追加
        addTextToNotionDatabase(selected)
        -- クリップボードを元に戻す
        hs.pasteboard.setContents(original)
    end)
end)