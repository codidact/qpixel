require 'rmagick'

class AdvertismentController < ApplicationController
    include Magick

    def codidact
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
        community_url.annotate ad, 600, 50, 0, 450, 'Try on codidact.com' do
            self.fill = 'white'
        end

        icon = Magick::ImageList.new('./app/assets/images/codidact.png')
        icon.resize_to_fit!(500, 300)
        ad.composite!(icon, CenterGravity, 0, -125, SrcAtopCompositeOp)

        on_codidact = Draw.new
        on_codidact.font_family = 'Roboto'
        on_codidact.font_weight = 600
        on_codidact.pointsize = 25
        on_codidact.gravity = CenterGravity
        on_codidact.annotate ad, 400, 50, 100, 200, 'The Open Source Q&A Platform.' do
            self.fill = '#666666'
        end

        slogan = Draw.new
        slogan.font_family = 'Roboto'
        slogan.font_weight = 500
        slogan.pointsize = 30
        slogan.gravity = NorthGravity
        position = 0
        wrap_text('Join our communities or build your own on codidact.com.', 500, 30).split("\n").each do |line|
            slogan.annotate ad, 500, 100, 50, 300 + position * 45, line do
                self.fill = '#333333'
            end
            position += 1
        end


        ad.format = 'PNG'
        ad.border!(2, 2, 'black')
        send_data ad.to_blob, :type => 'image/png', :disposition => 'inline'
    end

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
        slogan.gravity = NorthGravity
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

    def specific_question
        @post = Post.find(params[:id])
        if @post.question?
            return question_ad(@post)
        elsif @post.article?
            return article_ad(@post)
        end
        not_found
    end

    def random_question
        @post = @hot_questions.sample
        if @post.question?
            return question_ad(@post)
        elsif @post.article?
            return article_ad(@post)
        end
        not_found
    end

    private

    def wrap_text(text, width, font_size)
        columns = (width * 2.0 / font_size).to_i
        # Source: http://viseztrance.com/2011/03/texts-over-multiple-lines-with-rmagick.html
        text.split("\n").collect do |line|
            line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
    end

    def question_ad(question)
        ad = Image.new(600, 500)
        ad.background_color = 'white'

        uppoer_bar = Draw.new
        uppoer_bar.fill '#4B68FF'
        uppoer_bar.rectangle 0, 0, 600, 130
        uppoer_bar.draw ad

        answer = Draw.new
        answer.font_family = 'Roboto'
        answer.font_weight = 600
        answer.pointsize = 40
        answer.gravity = CenterGravity
        answer.annotate ad, 600, 50, 0, 10, 'Could you answer' do
            self.fill = 'white'
        end
        answer.annotate ad, 600, 50, 0, 70, 'this question?' do
            self.fill = 'white'
        end

        lower_bar = Draw.new
        lower_bar.fill '#4B68FF'
        lower_bar.rectangle 0, 450, 600, 500
        lower_bar.draw ad

        community_url = Draw.new
        community_url.font_family = 'Roboto'
        community_url.font_weight = 600
        community_url.pointsize = 20
        community_url.gravity = CenterGravity
        community_url.annotate ad, 600, 50, 0, 450, question.community.host do
            self.fill = 'white'
        end

        title = Draw.new
        title.font_family = 'Roboto'
        title.font_weight = 600
        title.pointsize = 50
        title.gravity = NorthGravity
        position = 0
        if question.title.length > 60
            title.pointsize = 40
            wrap_text(question.title, 500, 45).split("\n").each do |line|
                title.annotate ad, 500, 100, 50, 150 + position * 60, line do
                    self.fill = '#333333'
                end
                position += 1
            end
        else
            wrap_text(question.title, 500, 55).split("\n").each do |line|
                title.annotate ad, 500, 100, 50, 200 + position * 70, line do
                    self.fill = '#333333'
                end
                position += 1
            end
        end


        ad.format = 'PNG'
        ad.border!(2, 2, 'black')
        send_data ad.to_blob, :type => 'image/png', :disposition => 'inline'
    end

    def article_ad(article)
        ad = Image.new(600, 500)
        ad.background_color = 'white'

        uppoer_bar = Draw.new
        uppoer_bar.fill '#4B68FF'
        uppoer_bar.rectangle 0, 0, 600, 130
        uppoer_bar.draw ad

        answer = Draw.new
        answer.font_family = 'Roboto'
        answer.font_weight = 600
        answer.pointsize = 40
        answer.gravity = CenterGravity
        answer.annotate ad, 600, 120, 0, 10, 'Check out this article' do
            self.fill = 'white'
        end

        lower_bar = Draw.new
        lower_bar.fill '#4B68FF'
        lower_bar.rectangle 0, 450, 600, 500
        lower_bar.draw ad

        community_url = Draw.new
        community_url.font_family = 'Roboto'
        community_url.font_weight = 600
        community_url.pointsize = 20
        community_url.gravity = CenterGravity
        community_url.annotate ad, 600, 50, 0, 450, article.community.host do
            self.fill = 'white'
        end

        title = Draw.new
        title.font_family = 'Roboto'
        title.font_weight = 600
        title.pointsize = 50
        title.gravity = NorthGravity
        position = 0
        if article.title.length > 60
            title.pointsize = 40
            wrap_text(article.title, 500, 45).split("\n").each do |line|
                title.annotate ad, 500, 100, 50, 150 + position * 60, line do
                    self.fill = '#333333'
                end
                position += 1
            end
        else
            wrap_text(article.title, 500, 55).split("\n").each do |line|
                title.annotate ad, 500, 100, 50, 200 + position * 70, line do
                    self.fill = '#333333'
                end
                position += 1
            end
        end


        ad.format = 'PNG'
        ad.border!(2, 2, 'black')
        send_data ad.to_blob, :type => 'image/png', :disposition => 'inline'
    end
end
