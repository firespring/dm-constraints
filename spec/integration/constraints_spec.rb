require_relative '../spec_helper'

describe 'DataMapper::Constraints', "(with #{DataMapper::Spec.adapter_name})" do
  supported_by :all do
    before :all do
      @in_memory = defined?(DataMapper::Adapters::InMemoryAdapter) && @adapter.kind_of?(DataMapper::Adapters::InMemoryAdapter)
      @yaml      = defined?(DataMapper::Adapters::YamlAdapter)     && @adapter.kind_of?(DataMapper::Adapters::YamlAdapter)

      @skip = @in_memory || @yaml
    end

    before :all do
      class ::Article
        include DataMapper::Resource

        property :id,      Serial
        property :title,   String, :required => true
        property :content, Text

        has 1, :revision
        has n, :comments
        has n, :authors, :through => Resource
      end

      class ::Author
        include DataMapper::Resource

        property :first_name, String, :key => true
        property :last_name,  String, :key => true

        has n, :comments
        has n, :articles, :through => Resource
      end

      class ::Comment
        include DataMapper::Resource

        property :id,   Serial
        property :body, Text

        belongs_to :article
        belongs_to :author
      end

      # Used to test a belongs_to association with no has() association
      # on the other end
      class ::Revision
        include DataMapper::Resource

        property :id,   Serial
        property :text, String

        belongs_to :article
      end
    end

    describe 'create related objects' do
      before :all do
        class ::Comment
          belongs_to :article, :required => false
          belongs_to :author,  :required => false
        end

        class ::Revision
          belongs_to :article, :required => false
        end
      end

      it 'is able to create related objects with a foreign key constraint' do
        @article = Article.create(:title => 'Man on the Moon')
        @comment = @article.comments.create(:body => 'So true!')
      end

      it 'is able to create related objects with a composite foreign key constraint' do
        @author  = Author.create(:first_name => 'John', :last_name => 'Doe')
        @comment = @author.comments.create(:body => 'So true!')
      end

      supported_by :postgres, :mysql do
        it 'is not be able to create related objects with a failing foreign key constraint' do
          jruby = defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
          pending 'JRuby throws a DataObjects::SQLError for integrity errors, which is wrong' if jruby

          article = Article.create(:title => 'Man on the Moon')
          expect {
            Comment.create(:body => 'So true!', :article_id => article.id + 1)
          }.to raise_error(DataObjects::IntegrityError)
        end
      end
    end

    describe 'belongs_to without matching has association' do
      before do
        @article       = Article.create(:title => 'Man on the Moon')
        @other_article = Article.create(:title => 'Dolly cloned')
        @revision      = Revision.create(:text => 'Riveting!', :article => @other_article)
      end

      it 'destroys the parent if there are no children in the association' do
        expect(@article.destroy).to be(true)
        expect(@article.model.get(*@article.key)).to be_nil
      end

      it 'the child is destroyable' do
        expect(@revision.destroy).to be(true)
        expect(@revision.model.get(*@revision.key)).to be_nil
      end
    end

    describe 'constraint options' do
      describe 'when no constraint options are given' do
        before do
          @article      = Article.create(:title => 'Man on the Moon')
          @author       = Author.create(:first_name => 'John', :last_name => 'Doe')
          @other_author = Author.create(:first_name => 'Joe',  :last_name => 'Smith')
          @comment      = @other_author.comments.create(:body => 'So true!', :article => @article)
        end

        it 'destroys the parent if there are no children in the association' do
          expect(@author.destroy).to be(true)
          expect(@author.model.get(*@author.key)).to be_nil
        end

        it 'does not destroy the parent if there are children in the association' do
          expect(@other_author.destroy).to be(false)
          expect(@other_author.model.get(*@other_author.key)).not_to be_nil
        end
      end

      describe 'when :constraint => :protect is given' do
        before :all do
          class ::Article
            has 1, :revision, :constraint => :protect
            has n, :comments, :constraint => :protect
            has n, :authors,  :constraint => :protect, :through => Resource
          end

          class ::Author
            has n, :comments, :constraint => :protect
            has n, :articles, :constraint => :protect, :through => Resource
          end

          class ::Comment
            belongs_to :article
            belongs_to :author
          end

          class ::Revision
            belongs_to :article
          end
        end

        describe 'one-to-one associations' do
          before do
            @article  = Article.create(:title => 'Man on the Moon')
            @revision = Revision.create(:text => 'Riveting!', :article => @article)
          end

          it 'does not destroy the parent if there are children in the association' do
            expect(@article.destroy).to be(false)
            expect(@article.model.get(*@article.key)).not_to be_nil
          end

          it 'the child is destroyable' do
            expect(@revision.destroy).to be(true)
            expect(@revision.model.get(*@revision.key)).to be_nil
          end
        end

        describe 'one-to-many associations' do
          before do
            @article        = Article.create(:title => 'Man on the Moon')
            @author         = Author.create(:first_name => 'John', :last_name => 'Doe')
            @another_author = Author.create(:first_name => 'Joe',  :last_name => 'Smith')
            @comment        = @another_author.comments.create(:body => 'So true!', :article => @article)
          end

          it 'destroys the parent if there are no children in the association' do
            expect(@author.destroy).to be(true)
            expect(@author.model.get(*@author.key)).to be_nil
          end

          it 'does not destroy the parent if there are children in the association' do
            expect(@another_author.destroy).to be(false)
          end

          it 'the child is destroyable' do
            expect(@comment.destroy).to be(true)
            expect(@comment.model.get(*@comment.key)).to be_nil
          end
        end

        describe 'many-to-many associations' do
          before do
            pending 'The adapter does not support m:m associations yet' if @skip
          end

          before do
            @author         = Author.create(:first_name => 'John', :last_name => 'Doe')
            @another_author = Author.create(:first_name => 'Joe',  :last_name => 'Smith')
            @article        = Article.create(:title => 'Man on the Moon', :authors => [ @author ])
          end

          it 'destroys the parent if there are no children in the association' do
            expect(@another_author.destroy).to be(true)
            expect(@another_author.model.get(*@another_author.key)).to be_nil
          end

          it 'does not destroy the parent if there are children in the association' do
            expect(@author.articles).not_to eq []
            expect(@author.destroy).to be(false)
          end

          it 'the child is be destroyable' do
            @article.authors.clear
            expect(@article.save).to be(true)
            expect(@article.authors).to be_empty
          end
        end
      end

      describe 'when :constraint => :destroy! is given' do
        before :all do
          class ::Article
            has 1, :revision, :constraint => :destroy!
            has n, :comments, :constraint => :destroy!
            has n, :authors,  :constraint => :destroy!, :through => Resource
          end

          class ::Author
            has n, :comments, :constraint => :destroy!
            has n, :articles, :constraint => :destroy!, :through => Resource
          end

          class ::Comment
            belongs_to :article
            belongs_to :author
          end

          class ::Revision
            belongs_to :article
          end
        end

        describe 'one-to-one associations' do
          before do
            @article  = Article.create(:title => 'Man on the Moon')
            @revision = Revision.create(:text => 'Riveting!', :article => @article)
          end

          it 'lets the parent to be destroyed' do
            expect(@article.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
          end

          it 'destroys the children' do
            revision = @article.revision
            expect(@article.destroy).to be(true)
            expect(revision.model.get(*revision.key)).to be_nil
          end

          it 'the child is destroyable' do
            expect(@revision.destroy).to be(true)
            expect(@revision.model.get(*@revision.key)).to be_nil
          end
        end

        describe 'one-to-many associations' do
          before do
            @article         = Article.create(:title => 'Man on the Moon')
            @author          = Author.create(:first_name => 'John', :last_name => 'Doe')
            @comment         = @author.comments.create(:body => 'So true!',     :article => @article)
            @another_comment = @author.comments.create(:body => 'Nice comment', :article => @article)
          end

          it 'lets the parent to be destroyed' do
            expect(@author.destroy).to be(true)
            expect(@author.model.get(*@author.key)).to be_nil
          end

          it 'destroys the children' do
            expect(@author.destroy).to be(true)
            @author.comments.all? { |comment| expect(comment).to be_new }
          end

          it 'the child is destroyable' do
            expect(@comment.destroy).to be(true)
            expect(@comment.model.get(*@comment.key)).to be_nil
          end
        end

        describe 'many-to-many associations' do
          before do
            pending 'The adapter does not support m:m associations yet' if @skip
          end

          before do
            @article       = Article.create(:title => 'Man on the Moon')
            @other_article = Article.create(:title => 'Dolly cloned')
            @author        = Author.create(:first_name => 'John', :last_name => 'Doe', :articles => [ @article, @other_article ])
          end

          it 'lets the parent to be destroyed' do
            expect(@author.destroy).to be(true)
            expect(@author.model.get(*@author.key)).to be_nil
          end

          it 'destroys the children' do
            expect(@author.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
            expect(@other_article.model.get(*@other_article.key)).to be_nil
          end

          it 'the child is destroyable' do
            expect(@article.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
          end
        end
      end

      describe 'when :constraint => :destroy is given' do
        before :all do
          class ::Article
            has 1, :revision, :constraint => :destroy
            has n, :comments, :constraint => :destroy
            has n, :authors,  :constraint => :destroy, :through => Resource
          end

          class ::Author
            has n, :comments, :constraint => :destroy
            has n, :articles, :constraint => :destroy, :through => Resource
          end

          class ::Comment
            belongs_to :article
            belongs_to :author
          end

          class ::Revision
            belongs_to :article
          end
        end

        describe 'one-to-one associations' do
          before do
            @article  = Article.create(:title => 'Man on the Moon')
            @revision = Revision.create(:text => 'Riveting!', :article => @article)
          end

          it 'lets the parent to be destroyed' do
            expect(@article.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
          end

          it 'destroys the children' do
            revision = @article.revision
            expect(@article.destroy).to be(true)
            expect(revision.model.get(*revision.key)).to be_nil
          end

          it 'the child is destroyable' do
            expect(@revision.destroy).to be(true)
            expect(@revision.model.get(*@revision.key)).to be_nil
          end
        end

        describe 'one-to-many associations' do
          before do
            @article       = Article.create(:title => 'Man on the Moon')
            @author        = Author.create(:first_name => 'John', :last_name => 'Doe')
            @comment       = @author.comments.create(:body => 'So true!',        :article => @article)
            @other_comment = @author.comments.create(:body => "That's nonsense", :article => @article)
          end

          it 'lets the parent to be destroyed' do
            expect(@author.destroy).to be(true)
            expect(@author.model.get(*@author.key)).to be_nil
          end

          it 'destroys the children' do
            expect(@author.destroy).to be(true)
            @author.comments.all? { |comment| expect(comment).to be_new }
          end

          it 'the child is destroyable' do
            expect(@comment.destroy).to be(true)
            expect(@comment.model.get(*@comment.key)).to be_nil
          end
        end

        describe 'many-to-many associations' do
          before do
            pending 'The adapter does not support m:m associations yet' if @skip
          end

          before do
            @article       = Article.create(:title => 'Man on the Moon')
            @other_article = Article.create(:title => 'Dolly cloned')
            @author        = Author.create(:first_name => 'John', :last_name => 'Doe', :articles => [ @article, @other_article ])
          end

          it 'destroys the parent and the children, too' do
            expect(@author.destroy).to be(true)
            expect(@author.model.get(*@author.key)).to be_nil

            expect(@article.model.get(*@article.key)).to be_nil
            expect(@other_article.model.get(*@other_article.key)).to be_nil
          end

          it 'the child is destroyable' do
            expect(@article.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
          end
        end
      end

      describe 'when :constraint => :set_nil is given' do
        before :all do
          # NOTE: M:M Relationships are not supported by :set_nil,
          # see 'when checking constraint types' tests at bottom

          class ::Article
            has 1, :revision, :constraint => :set_nil
            has n, :comments, :constraint => :set_nil
          end

          class ::Author
            has n, :comments, :constraint => :set_nil
          end

          class ::Comment
            belongs_to :article, :required => false
            belongs_to :author,  :required => false
          end

          class ::Revision
            belongs_to :article, :required => false
          end
        end

        describe 'one-to-one associations' do
          before do
            @article  = Article.create(:title => 'Man on the Moon')
            @revision = Revision.create(:text => 'Riveting!', :article => @article)
          end

          it 'lets the parent to be destroyed' do
            expect(@article.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
          end

          it "sets the child's foreign_key id to nil" do
            revision = @article.revision
            expect(@article.destroy).to be(true)
            expect(revision.article).to be_nil
            expect(revision.model.get(*revision.key).article).to be_nil
          end

          it 'the child is destroyable' do
            expect(@revision.destroy).to be(true)
            expect(@revision.model.get(*@revision.key)).to be_nil
          end
        end

        describe 'one-to-many associations' do
          before do
            @author        = Author.create(:first_name => 'John', :last_name => 'Doe')
            @comment       = @author.comments.create(:body => 'So true!')
            @other_comment = @author.comments.create(:body => "That's nonsense")
          end

          it 'lets the parent be destroyed' do
            expect(@author.destroy).to be(true)
            expect(@author.model.get(*@author.key)).to be_nil
          end

          it 'sets the foreign_key ids of children to nil' do
            expect(@author.destroy).to be(true)
            @author.comments.all? { |comment| expect(comment.author).to be_nil }
          end

          it 'the children are destroyable' do
            expect(@comment.destroy).to be(true)
            expect(@comment.model.get(*@comment.key)).to be_nil

            expect(@other_comment.destroy).to be(true)
            expect(@other_comment.model.get(*@other_comment.key)).to be_nil
          end
        end
      end

      describe 'when :constraint => :skip is given' do
        before :all do
          class ::Article
            has 1, :revision, :constraint => :skip
            has n, :comments, :constraint => :skip
            has n, :authors,  :constraint => :skip, :through => Resource
          end

          class ::Author
            has n, :comments, :constraint => :skip
            has n, :articles, :constraint => :skip, :through => Resource
          end

          class ::Comment
            belongs_to :article
            belongs_to :author
          end

          class ::Revision
            belongs_to :article
          end
        end

        describe 'one-to-one associations' do
          before do
            @article  = Article.create(:title => 'Man on the Moon')
            @revision = Revision.create(:text => 'Riveting!', :article => @article)
          end

          it 'lets the parent be destroyed' do
            expect(@article.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
          end

          it 'lets the children become orphan records' do
            expect(@article.destroy).to be(true)
            expect(@revision.model.get(*@revision.key).article).to be_nil
          end

          it 'the child is destroyable' do
            expect(@revision.destroy).to be(true)
            expect(@revision.model.get(*@revision.key)).to be_nil
          end
        end

        describe 'one-to-many associations' do
          before do
            @article       = Article.create(:title => 'Man on the Moon')
            @author        = Author.create(:first_name => 'John', :last_name => 'Doe')
            @comment       = @author.comments.create(:body => 'So true!',        :article => @article)
            @other_comment = @author.comments.create(:body => "That's nonsense", :article => @article)
          end

          it 'lets the parent be destroyed' do
            expect(@author.destroy).to be(true)
            expect(@author.model.get(*@author.key)).to be_nil
          end

          it 'lets the children become orphan records' do
            expect(@author.destroy).to be(true)
            expect(@comment.model.get(*@comment.key).author).to be_nil
            expect(@other_comment.model.get(*@other_comment.key).author).to be_nil
          end

          it 'the children are destroyable' do
            expect(@comment.destroy).to be(true)
            expect(@other_comment.destroy).to be(true)
            expect(@other_comment.model.get(*@other_comment.key)).to be_nil
          end
        end

        describe 'many-to-many associations' do
          before do
            pending 'The adapter does not support m:m associations yet' if @skip
          end

          before do
            @article       = Article.create(:title => 'Man on the Moon')
            @other_article = Article.create(:title => 'Dolly cloned')
            @author        = Author.create(:first_name => 'John', :last_name => 'Doe', :articles => [ @article, @other_article ])
          end

          it 'the children are be destroyable' do
            expect(@article.destroy).to be(true)
            expect(@article.model.get(*@article.key)).to be_nil
          end
        end
      end

      describe 'when checking constraint types' do
        # M:M relationships results in a join table composed of composite (composed of two parts)
        # primary key.
        # Setting a portion of this primary key is not possible for two reasons:
        # 1. the columns are defined as :required => true
        # 2. there could be duplicate rows if more than one of either of the types
        #   was deleted while being associated to the same type on the other side of the relationship
        #   Given
        #   Author(name: John Doe, ID: 1) =>
        #       Articles[Article(title: Man on the Moon, ID: 1), Article(title: Dolly cloned, ID: 2)]
        #   Author(Name: James Duncan, ID: 2) =>
        #       Articles[Article(title: Man on the Moon, ID: 1), Article(title: The end is nigh, ID: 3)]
        #
        #   Table authors_articles would look like (author_id, article_id)
        #     (1, 1)
        #     (1, 2)
        #     (2, 1)
        #     (2, 3)
        #
        #   If both articles were deleted and the primary key was set to null
        #     (null, 1)
        #     (null, 2)
        #     (null, 1) # duplicate error!
        #     (null, 3)
        #
        #   I would suggest setting :constraint to :skip in this scenario which will leave
        #     you with orphaned rows.
        it 'raises an error if :set_nil is given for a M:M relationship' do
          expect {
            class ::Article
              has n, :authors, :through => Resource, :constraint => :set_nil
            end

            class ::Author
              has n, :articles, :through => Resource, :constraint => :set_nil
            end
          }.to raise_error(ArgumentError)
        end

        it 'raises an error if an unknown type is given' do
          expect do
            class ::Author
              has n, :articles, :constraint => :chocolate
            end
          end.to raise_error(ArgumentError)
        end
      end
    end
  end
end
