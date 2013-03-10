#!/ruby/bin/ruby

require 'open-uri'
require 'json'

WIKIPEDIA_HOST = "http://ja.wikipedia.org/wiki"

HATEB_API_ENDPOINT = "http://b.hatena.ne.jp/entry/jsonlite/"

# wiki$B5-;v$NA4%$%s%G%C%/%9$r3JG<$7$?%U%!%$%k(B
# http://dumps.wikimedia.org/jawiki/$B$h$j<hF@2DG=(B
ARTICLE_INDEX_FILE_PATH = "./jawiki-20130125-pages-articles-multistream-index.txt.bz2"

# $B=hM}BP>]$H$9$k$O$F$J%V%C%/%^!<%/?t$N:GDcCM(B
MIN_BOOKMARK_COUNT = 10;

# $B7k2L$r=PNO$9$k%Q%9$r;XDj(B
OUTPUT_FILE_PATH = "./articles_bookmark_info.csv"

# $B$O$F$J%V%C%/%^!<%/>pJs$r<hF@$9$k$?$a$N%(%s%I%]%$%s%H$r<hF@(B
def get_endpoint_path(article_title)
    encoded_url = URI.encode(WIKIPEDIA_HOST + '/' + article_title)
    HATEB_API_ENDPOINT + "?url=" + encoded_url
end

# $B$O$F$J%V%C%/%^!<%/(BAPI$B$rC!$->pJs$r<hF@(B
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

# $B5-;v$,(Bwikipedia$B<+BN$N%,%$%IMQ5-;v$+$I$&$+$rH=CG(B
def is_official_guide_article?(article_title)
    article_title == 'Wikipedia'
end

# $B:w0z>pJs$+$i(Bwikipedia$B$N5-;v%?%$%H%k$r<hF@(B
def get_article_title(article_index)
    article_index.split(':')[2]
end

# $B%V%C%/%^!<%/$KIUM?$5$l$?A4$F$N%?%0$r<hF@$9$k(B
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

# $B%G!<%?$r(BCSV$B7A<0$G%U%!%$%k$KEG$-=P$9(B
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

# $B%a%$%s%m%8%C%/(B
index_no = 0;
output   = []
cmd      = 'bzcat ' + ARTICLE_INDEX_FILE_PATH;

open('|' + cmd){|file|
    while article_index = file.gets

        index_no += 1

        # $B5-;v%?%$%H%k<hF@(B
        article_title = get_article_title(article_index)

        # Wikipedia$B$N8x<0%,%$%I5-;v$O%9%-%C%W(B
        if is_official_guide_article?(article_title)
            next
        end

        # $B$O$F%V>pJs$r(BAPI$B$+$i<hF@(B
        hateb_info = get_hateb_info(article_title)
        if hateb_info == nil
            next
        end

        # $B%V%C%/%^!<%/$,;XDjCML$K~$J$i%9%-%C%W(B
        if hateb_info['count'].to_i < MIN_BOOKMARK_COUNT
            next
        end

        # $B$O$F%V$N%?%0>pJs$r<hF@(B
        tags = get_all_tags_from_bookmarks(hateb_info['bookmarks'])

        # $B=PNO$9$k%G!<%?$rG[Ns$K5M$a$k(B
        article_info_4_output = []
        article_info_4_output << article_title.strip
        article_info_4_output << hateb_info['count']
        article_info_4_output << tags.join(':::')
        output << article_info_4_output

        puts "[DATA PUSHED]line_no:#{index_no}: title:#{article_title}\n"

        # 1000$B7oKh$K%G!<%?$r%U%!%$%k=PNO(B
        if output.length >= 1000
            output_csv_data(output)
            output = []
        end

    end
}
