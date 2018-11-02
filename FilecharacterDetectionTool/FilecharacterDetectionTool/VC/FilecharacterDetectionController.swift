//
//  MainViewController.swift
//  FilecharacterDetectionTool
//
//  Created by zhengzeqin on 2018/10/30.
//  Copyright © 2018年 zhengzeqin. All rights reserved.
//

import Cocoa
enum ScanProjectType {
    case iOS
    case android
    case other
}

class FilecharacterDetectionController: NSViewController {

    
    @IBOutlet weak var directoryTextField: NSTextField!
    @IBOutlet weak var scanTextView: NSTextView!
    @IBOutlet weak var scanResultTextView: NSTextView!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var iOSRadio: NSButton!
    @IBOutlet weak var androidRadio: NSButton!
    @IBOutlet weak var otherRadio: NSButton!
    @IBOutlet weak var scanButton: NSButton!
    @IBOutlet weak var existSimpleCountTextField: NSTextField!
    @IBOutlet weak var currentIndexTextField: NSTextField!
    private lazy var scanProjectType = ScanProjectType.iOS
    
    static let kStopScanText = "已经停止了扫描"
    
    /// 扫描到第几个 进度
    private lazy var currentScanIndex = 0
    /// 扫描存在多少个简体字
    private lazy var existSimpleCount = 0
    
    private let fileManager = FileManager.default
    
    /// 文件目录
    private lazy var filePathArray = [String]()

    
    /// 需要扫描的文本内容
    private var scanTextViewTxt:String?
    /// 扫描结果的文本内容
    private var scanResultTextViewTxt:String?
    /// 进度提示
    private var progressLabelTxt:String?

    /// 扫描存在多个简体字
    private lazy var scanResultCount = 0
    
    /// 停止扫描
    private lazy var stopScan = false

    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        creatUI()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    //MARK: - IBAction
    @IBAction func searchFileBtnAction(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        if openPanel.runModal() == NSApplication.ModalResponse.OK {
            directoryTextField.stringValue = (openPanel.directoryURL?.path)!
        }
    }
    
    @IBAction func scanBtnAction(_ sender: NSButton) {
        stopScan = !stopScan
        sender.title = stopScan ? "停止扫描" : "开始扫描"
        if !stopScan {return}
        if (iOSRadio.state.rawValue == 1) {
            scanProjectType = .iOS
        }else if (iOSRadio.state.rawValue == 1) {
            scanProjectType = .android
        }else{
            scanProjectType = .other
        }

        configureScan()
        let path = directoryTextField.stringValue
        if path.count > 0 {
            beginScanFile()
        }else {
            let alert = NSAlert()
            alert.messageText = "提示您请选择扫描项目目录"
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }

    @IBAction func radionBtnAction(_ sender: NSButton) {
        androidRadio.state = NSControl.StateValue.init(0)
        iOSRadio.state = NSControl.StateValue.init(0)
        otherRadio.state = NSControl.StateValue.init(0)
        sender.state  = NSControl.StateValue.init(1)
    }
    
    
    //MARK: - Private Method
    /// 开始扫描的初始化数据
    func configureScan() {
        currentScanIndex = 0
        existSimpleCount = 0
        clearContent()
    }
    
    /// 开始扫描
    func beginScanFile()  {
        let path = directoryTextField.stringValue
        progressLabel.stringValue = "扫描之前，需要计算统计项目所有的类，马上开始别着急请耐心等待一小会........^_^"
        
        DispatchQueue.global().async(execute: {
            let directoryFileNameArray = try! self.fileManager.contentsOfDirectory(atPath: path)
            self.startCalculateAllClass(directoryFileNameArray, path: path)
            if self.progressLabel.stringValue == FilecharacterDetectionController.kStopScanText {return}
            DispatchQueue.main.async {
                self.scanButton.title = "开始扫描"
                self.stopScan = false
                self.saveFileToDisk()
            }
        })
    }
    
    /// 保存结果
    func saveFileToDisk() {
        let alert = NSAlert()
        alert.messageText = "已经帮你扫描完成了,是否要把扫描日志保存到文件？"
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "取消")
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if modalResponse.rawValue == 1000 {
                let savaPanel = NSSavePanel()
                savaPanel.message = "Choose the path to save the document"
                savaPanel.allowedFileTypes = ["txt"]
                savaPanel.allowsOtherFileTypes = false
                savaPanel.canCreateDirectories = true
                savaPanel.beginSheetModal(for: self.view.window!, completionHandler: {[unowned self] (code) in
                    if code.rawValue == 1 {
                        do {
                            let originTxt = self.scanResultTextView.string
                            try originTxt.write(toFile: savaPanel.url!.path, atomically: true, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
                        }catch {
                            print("写文件异常")
                        }
                    }
                })
            }
        })
    }
    
    ///////////////
    
    /// 情况面板内容
    private func clearContent() {
        setScanContent(content: "")
        setScanResultContent(content: "")
    }
    
    
    /// 需要扫描的文件内容
    private func setScanContent(content: String?) {
        if content != nil {
            let attrContent = NSMutableAttributedString(string: content!)
            scanTextView.textStorage?.setAttributedString(attrContent)
            scanTextView.textStorage?.font = NSFont.systemFont(ofSize: 14)
            scanTextView.textStorage?.foregroundColor = NSColor.orange
            scanTextView.scroll(NSPoint(x: 0, y: scanTextView.textContainer!.containerSize.height))
        }
    }
    
    
    /// 扫描的文件内容结果
    private func setScanResultContent(content: String?) {
        if content != nil {
            let attrContent = NSMutableAttributedString(string: content!)
            scanResultTextView.textStorage?.setAttributedString(attrContent)
            scanResultTextView.textStorage?.font = NSFont.systemFont(ofSize: 14)
            scanResultTextView.textStorage?.foregroundColor = NSColor.orange
            scanResultTextView.scroll(NSPoint(x: 0, y: scanResultTextView.textContainer!.containerSize.height))
        }
    }
    
}

// MARK: - UI
extension FilecharacterDetectionController {
    fileprivate func creatUI()  {
        scanTextView.backgroundColor = NSColor(red: 40.0 / 255.0, green: 40.0 / 255.0, blue: 40.0 / 255.0, alpha: 1.0)
        scanResultTextView.backgroundColor = NSColor(red: 40.0 / 255.0, green: 40.0 / 255.0, blue: 40.0 / 255.0, alpha: 1.0)
    }
}


// MARK: - DealData
extension FilecharacterDetectionController {
    
    /// 扫描所有类文件
    private func startCalculateAllClass(_ directoryFileNameArray :[String]!, path: String!) {
        autoreleasepool {
            if directoryFileNameArray != nil {
                for (_, fileName) in directoryFileNameArray.enumerated() {
                    
                    if self.stopScan == false {
                        break
                    }
                
                    if fileName.hasSuffix(".xcassets") || fileName.hasSuffix(".bundle") {continue}
                    var isDirectory = ObjCBool(true)
                    let pathName = path + "/" + fileName
                    let exist = fileManager.fileExists(atPath: pathName, isDirectory: &isDirectory)
                    if exist && isDirectory.boolValue {
                        let tempDirectoryFileNameArray = try! fileManager.contentsOfDirectory(atPath: pathName)
                        startCalculateAllClass(tempDirectoryFileNameArray, path: pathName)
                    }else {
                        switch scanProjectType {
                            case .android:
                                if fileName != "R.java" && fileName != "BuildConfig.java" {
                                    if fileName.hasSuffix(".class")
                                        || fileName.hasSuffix(".java")
                                        || fileName.hasSuffix(".kt"){
                                        self.execScan(filePath: pathName)
                                    }
                                }
                            case .iOS:
                                if fileName.hasSuffix(".swift") || fileName.hasSuffix(".m") ||  fileName.hasSuffix(".h") {
                                    self.execScan(filePath: pathName)
                                }
                            case .other:
                                self.execScan(filePath: pathName)
                        }
                    }
                }
            }
        }
    }
    
    
    /// 扫描引擎
    ///
    /// - Parameter filePath: 要扫描文件目录
    fileprivate func execScan(filePath:String) {
        autoreleasepool {
            DispatchQueue.main.sync {
                let originTxt = self.scanTextView.string
                let fileName:String = filePath.components(separatedBy: "/").last ?? filePath
                let string = ">>>>> \(fileName)" + "\n"
                self.setScanContent(content: originTxt + string)
                self.progressLabel.stringValue = filePath
                self.currentScanIndex+=1
                self.currentIndexTextField.stringValue = "扫描第\(self.currentScanIndex)个文件: "
            }
            checkFile(filePath: filePath)
        }
    }
    
    /// 检测文件内容并输出
    fileprivate func checkFile(filePath:String){
        let contentData = try! Data(contentsOf: URL(fileURLWithPath: filePath), options: NSData.ReadingOptions.mappedIfSafe);
        let fileContent = NSString(data: contentData, encoding: String.Encoding.utf8.rawValue)
        if let fileContent = fileContent {
//            let handleFileContent = fileContent.replacingOccurrences(of: " ", with: "")
            let handleFileContent = ZQTool.replaceAnnotationContent(fileContent)
            let result: (count:Int, string:String) = ZQTool.isHadSimpleString(str: handleFileContent,isFilterAnnotation: true)
            let count = result.count
            if count > 1 {
                DispatchQueue.main.sync(execute: {
                    let fileName:String = filePath.components(separatedBy: "/").last ?? filePath
                    self.existSimpleCount += count
                    let originTxt = self.scanResultTextView.string
                    self.existSimpleCountTextField.stringValue = "简体字个数 \(self.existSimpleCount)个"
                    self.setScanResultContent(content: originTxt + ">>>>> " + fileName + ":\n" + result.string + "\n")
                })
            }
        }
    }
    
    
    
}

