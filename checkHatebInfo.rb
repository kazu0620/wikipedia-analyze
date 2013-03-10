#!/ruby/bin/ruby

require 'open-uri'
require 'json'

WIKIPEDIA_HOST = "http://ja.wikipedia.org/wiki"

HATEB_API_ENDPOINT = "http://b.hatena.ne.jp/entry/jsonlite/"

# wiki記事の全インデックスを格納したファイル
# http://dumps.wikimedia.org/jawiki/より取得可能
ARTICLE_INDEX_FILE_PATH = "./jawiki-20130125-pages-articles-multistream-index.txt.bz2"

# 処理対象とするはてなブックマーク数の最低値
MIN_BOOKMARK_COUNT = 10;

# 結果を出力するパスを指定
OUTPUT_FILE_PATH = "./articles_bookmark_info.csv"

# はてなブックマーク情報を取得するためのエンドポイントを取得
def get_endpoint_path(article_title)
    encoded_url = URI.encode(WIKIPEDIA_HOST + '/' + article_title)
    HATEB_API_ENDPOINT + "?url=" + encoded_url
end

# はてなブックマークAPIを叩き情報を取得
def get_hateb_info(article_title)
    json_data = open( get_endpoint_path(article_title) ).read

    if json_data == 'null'
        return nil
    end

    JSON.parse(json_data)

    rescue => e
        puts "[ERROR]: #{e.message}"
        return nil
end

# 記事がwikipedia自体のガイド用記事かどうかを判断
def is_official_guide_article?(article_title)
    article_title == 'Wikipedia'
end

# 索引情報からwikipediaの記事タイトルを取得
def get_article_title(article_index)
    article_index.split(':')[2]
end

# ブックマークに付与された全てのタグを取得する
def get_all_tags_from_bookmarks(bookmarks)
    tags = []
    bookmarks.each{|bookmark|
        bookmark["tags"].each{|tag|
            if !tags.include?(tag)
                tags << tag
            end
        }
    }
    tags
    rescue => e
        puts "[ERROR]: #{e.message}"
end

# データをCSV形式でファイルに吐き出す
def output_csv_data(output)
    outputcsv = ""
    output.each{|line|
        outputcsv += line.join(",") + "\n"
    }
    begin
        f = open(OUTPUT_FILE_PATH, 'a'){|f|
            f.write outputcsv
        }
    rescue => e
        puts "[ERROR]: #{e.message}"
    else
        puts "[FILE WRITE SUCCESS]"
    end
end

# メインロジック
index_no = 0;
output   = []
cmd      = 'bzcat ' + ARTICLE_INDEX_FILE_PATH;

open('|' + cmd){|file|
    while article_index = file.gets

        index_no += 1

        # 記事タイトル取得
        article_title = get_article_title(article_index)

        # Wikipediaの公式ガイド記事はスキップ
        if is_official_guide_article?(article_title)
            next
        end

        # はてブ情報をAPIから取得
        hateb_info = get_hateb_info(article_title)
        if hateb_info == nil
            next
        end

        # ブックマークが指定値未満ならスキップ
        if hateb_info['count'].to_i < MIN_BOOKMARK_COUNT
            next
        end

        # はてブのタグ情報を取得
        tags = get_all_tags_from_bookmarks(hateb_info['bookmarks'])

        # 出力するデータを配列に詰める
        article_info_4_output = []
        article_info_4_output << article_title.strip
        article_info_4_output << hateb_info['count']
        article_info_4_output << tags.join(':::')
        output << article_info_4_output

        puts "[DATA PUSHED]line_no:#{index_no}: title:#{article_title}\n"

        # 1000件毎にデータをファイル出力
        if output.length >= 1000
            output_csv_data(output)
            output = []
        end

    end
}
