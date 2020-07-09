require 'rmagick'

class AdvertismentController < ApplicationController
    include Magick

    def community
        ad = Image.new(600, 500)
        ad.background_color = 'white'

        lower_bar = Draw.new
        lower_bar.fill '#4B68FF'
        lower_bar.rectangle 0, 450, 600, 500
        lower_bar.draw ad

        community_url = Draw.new
        community_url.font_family = 'Roboto'
        community_url.font_weight = 600
        community_url.pointsize = 20
        community_url.gravity = CenterGravity
        community_url.annotate ad, 600, 50, 0, 450, @community.host do
            self.fill = 'white'
        end

        icon_path = SiteSetting['SiteLogoPath']
        unless icon_path.present?
            name = @community.name
            community_name = Draw.new
            community_name.font_family = 'Roboto'
            community_name.font_weight = 800
            community_name.pointsize = (50 + 100.0/name.length)
            community_name.gravity = CenterGravity
            community_name.annotate ad, 600, 250, 0, 0, name do
                self.fill = 'black'
            end
        else
            icon = Magick::ImageList.new('./app/assets/images/' + File.basename(icon_path))
            icon.resize_to_fit!(400, 200)
            ad.composite!(icon, CenterGravity, 0, -125, SrcAtopCompositeOp)
        end

        on_codidact = Draw.new
        on_codidact.font_family = 'Roboto'
        on_codidact.font_weight = 600
        on_codidact.pointsize = 25
        on_codidact.gravity = EastGravity
        on_codidact.annotate ad, 0, 50, 500, 200, 'on codidact.com' do
            self.fill = '#666666'
        end

        slogan = Draw.new
        slogan.font_family = 'Roboto'
        slogan.font_weight = 500
        slogan.pointsize = 30
        slogan.gravity = NorthWestGravity
        position = 0
        wrap_text(SiteSetting['SiteAdSlogan'], 500, 30).split("\n").each do |line|
            slogan.annotate ad, 500, 100, 50, 300 + position * 45, line do
                self.fill = '#333333'
            end
            position += 1
        end


        ad.format = 'PNG'
        ad.border!(2, 2, 'black')
        send_data ad.to_blob, :type => 'image/png', :disposition => 'inline'
    end

    private

    def wrap_text(text, width, font_size)
        columns = (width * 2.5 / font_size).to_i
        # Source: http://viseztrance.com/2011/03/texts-over-multiple-lines-with-rmagick.html
        text.split("\n").collect do |line|
            line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
    end
end
