# encoding: utf-8

RSpec.describe DoubleEntry::BalanceCalculator do
  describe '#calculate' do
    let(:account) { DoubleEntry.account(:test, :scope => scope) }
    let(:scope) { User.make! }
    let(:from) { nil }
    let(:to) { nil }
    let(:at) { nil }
    let(:code) { nil }
    let(:codes) { nil }
    let(:relation) { double.as_null_object }

    before do
      allow(DoubleEntry::Line).to receive(:where).and_return(relation)
      DoubleEntry::BalanceCalculator.calculate(
        account,
        :scope => scope,
        :from => from,
        :to => to,
        :at => at,
        :code => code,
        :codes => codes,
      )
    end

    describe 'what happens with different times' do
      context 'when we want to sum the lines before a given created_at date' do
        let(:at) { Time.zone.parse('2014-06-19 15:09:18 +1000') }

        it 'scopes the lines summed to times before (or at) the given time' do
          expect(relation).to have_received(:where).with(
            'created_at <= ?', Time.zone.parse('2014-06-19 15:09:18 +1000')
          )
        end

        context 'when a time range is also specified' do
          let(:from) { Time.zone.parse('2014-06-19 10:09:18 +1000') }
          let(:to) { Time.zone.parse('2014-06-19 20:09:18 +1000') }

          it 'ignores the time range when summing the lines' do
            expect(relation).to_not have_received(:where).with(
              :created_at => Time.zone.parse('2014-06-19 10:09:18 +1000')..Time.zone.parse('2014-06-19 20:09:18 +1000'),
            )
            expect(relation).to_not have_received(:sum)
          end
        end
      end

      context 'when we want to sum the lines between a given range' do
        let(:from) { Time.zone.parse('2014-06-19 10:09:18 +1000') }
        let(:to) { Time.zone.parse('2014-06-19 20:09:18 +1000') }

        it 'scopes the lines summed to times within the given range' do
          expect(relation).to have_received(:where).with(
            :created_at => Time.zone.parse('2014-06-19 10:09:18 +1000')..Time.zone.parse('2014-06-19 20:09:18 +1000'),
          )
          expect(relation).to have_received(:sum).with(:amount)
        end
      end
    end

    context 'when a single code is provided' do
      let(:code) { 'code1' }

      it 'scopes the lines summed by the given code' do
        expect(relation).to have_received(:where).with(:code => ['code1'])
        expect(relation).to have_received(:sum).with(:amount)
      end
    end

    context 'when a list of codes is provided' do
      let(:codes) { %w(code1 code2) }

      it 'scopes the lines summed by the given codes' do
        expect(relation).to have_received(:where).with(:code => %w(code1 code2))
        expect(relation).to have_received(:sum).with(:amount)
      end
    end

    context 'when no codes are provided' do
      it 'does not scope the lines summed by any code' do
        expect(relation).to_not have_received(:where).with(:code => anything)
        expect(relation).to_not have_received(:sum).with(:amount)
      end
    end
  end
end
