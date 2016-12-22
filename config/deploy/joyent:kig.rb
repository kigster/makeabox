set :ruby_version, '2.3.3'
set :target_os, 'sunos'
set :rails_env, 'production'

require_relative '../../lib/capistrano/loader/os'

server 'kig.re', roles: %w{app db web worker}, user: 'kig'

set :gem_config, { nokogiri: <<-EOF.gsub(/\n\s{0,}/, ' ')
                    --use-system-libraries
                    --with-xml2-lib=/opt/local/lib
                    --with-xml2-include=/opt/local/include/libxml2
                    --with-xslt-lib=/opt/local/lib
                    --with-xslt-include=/opt/local/include/libxslt
                    --with-iconv-lib=/opt/local/lib
                    --with-iconv-include=/opt/local/include
                    --with-zlib-dir=/opt/local/lib
                   EOF
}

