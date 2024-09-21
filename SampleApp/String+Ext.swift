//
//  String+Ext.swift
//  SampleApp
//
//  Created by lee on 2024/9/21.
//

import Foundation

extension String {
    var isImage: Bool {
        let fileType = self.split(separator: ".").last ?? ""
        return ["png","jpg"].contains { $0.lowercased() == String(fileType)}
    }
}


extension String {
    var local: String {
        NSLocalizedString(self,
                          value:self,
                          comment: self)
    }
    
    @discardableResult
    func local(value: String, comment: String) -> String {
        NSLocalizedString(self,
                          value:value,
                          comment: comment)
    }
}
