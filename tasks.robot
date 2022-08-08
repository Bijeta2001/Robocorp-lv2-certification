*** Settings ***
Documentation     Orders robot from RobotSpareBin Industries Inc.
...               saves the order HTML receipt as a PDF file.
...               saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt
...               Creates ZIP archve of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Tables
Library           RPA.PDF
Library           OperatingSystem
Library           RPA.Dialogs
Library           RPA.FileSystem

*** Variables ***

${head}                   id:head
${body}                   body
${legs}                   xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
${address}                id:address
${receipt}                id:receipt
${receiptPdf}             "C:\Users\BijetaLama\Desktop\level2\OrderRobot\output\receipts\1.pdf"
${robot-preview-image}    //div[@id="robot-preview-image"]
${receipt_folder}         ${CURDIR}${/}output${/}receipts
${image_folder}           ${CURDIR}${/}output${/}images
${receiptZip}             ${CURDIR}${/}output${/}receipts.zip
${GLOBAL_RETRY_AMOUNT}=       10x
${GLOBAL_RETRY_INTERVAL}=     1s

*** Tasks ***

Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read Table From Csv    orders.csv    dialect=excel    header=True
    FOR    ${row}    IN    @{table}
        Log    ${row}
    END
    [Return]    ${table}

Fill the form
    [Arguments]    ${row}
    Select From List By Value        ${head}           ${row}[Head]  
    Select Radio Button              ${body}           ${row}[Body]
    Input Text                       ${legs}           ${row}[Legs]
    Input Text                       ${address}        ${row}[Address]  

Preview the robot
    Click Button    Preview

Submit the order
    Click Button    order
    
Store the receipt as a pdf file
    [Arguments]    ${orderNumber}
    FOR  ${i}  IN RANGE  ${10}
        ${alert}=  Is Element Visible  ${receipt}  
        Exit For Loop If  '${alert}'=='True'  
        Click Button  order     
    END
    ${receipt}=    Get Element Attribute    ${receipt}    outerHTML
    Html To Pdf    ${receipt}    ${receipt_folder}${/}${orderNumber}.pdf
    Set Local Variable    ${pdf}    ${receipt_folder}${/}${orderNumber}.pdf
    [Return]    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    ${robot}=    Capture Element Screenshot    ${robot-preview-image}    ${image_folder}${/}${orderNumber}.jpeg
    [Return]    ${robot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${receiptPdf}
    Open Pdf    ${receiptPdf}
    ${files}=    Create List    ${receiptPdf}    ${screenshot}
    Add Files To PDF    ${files}    ${receiptPdf}

Go to order another robot
    Click Button    order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}${receipt_folder}    receipts.zip
