################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

require 'spec_helper'

describe Script do
  describe '#file_path' do
    context 'with new instance' do
      it 'returns nil' do
        server = build(:general_script)
        expect(server.file_path).to eq nil
      end
    end

    context 'with persisted instance' do
      it 'returns the path' do
        server = create(:general_script, id: 379)
        allow(server).to receive(:default_path).and_return '/some/default_path'
        expect(server.file_path).to eq '/some/default_path/379.script'
      end
    end
  end

  describe '#created_by' do
    context 'with created_by value not nil' do
      it 'returns the path' do
        script = create(:general_script)
        expect(script.created_by).to be == @user.id
      end
    end
  end

end

