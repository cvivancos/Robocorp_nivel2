*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
...                Saves the order HTML receipt as a PDF file.
...                Saves the screenshot of the ordered robot.
...                Embeds the screenshot of the robot to the PDF receipt.
...                Creates ZIP archive of the receipts and the images.
...                Author: www.github.com/joergschultzelutter

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    Collections
Library    RPA.Robocloud.Secrets
Library    OperatingSystem
Library    BuiltIn

*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order

${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip
${csv_url}        https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form for one person    ${row}
        Wait Until Keyword Succeeds    3x    0.5s    Preview the robot
        Wait Until Keyword Succeeds    3x    0.5s    Submit the order
        ${orderid}  ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=    Store the order receipt as a PDF file    ORDER_NUMBER=${orderid}  
        Embebed the robot screenshot to the receipt PDF file    IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Create a ZIP file of receipt PDF files
    Log Out and Close the Browser



*** Keywords ***
Open the robot order website
    Log To Console    Opening the robot order website
    Open Available Browser    ${url}
    Maximize Browser Window


Get orders
    Log To Console    Descargando csv
    Download    url=${csv_url}    target_file=${orders_file}    overwrite=${True}
    ${table}=    Read table from CSV    path=${orders_file}
    [Return]    ${table}


Close the annoying modal
    Log To Console    Closing the annoying modal
    Wait Until Element Is Visible    class:alert-buttons
    Click Button    OK


Fill the form for one person
    [Arguments]    ${myrow}
    # ${order_no}   ${myrow}[Order number]
    # ${head}       ${myrow}[Head]
    # ${body}       ${myrow}[Body]
    # ${legs}       ${myrow}[Legs]
    # ${address}    ${myrow}[Address]
    Log To Console    Filling the form
    Select From List By Value    head    ${myrow}[Head]
    Select Radio Button    body    ${myrow}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${myrow}[Legs]
    Input Text    address    ${myrow}[Address]


Preview the robot
    Log To Console    Previewing the robot
    Click Button    id:preview 
    Wait Until Element Is Visible    id:robot-preview-image


Submit the order
    Log To Console    Submitting the order
    Click Button    id:order
    Page Should Contain Element    id:receipt


Take a screenshot of the robot
    Log To Console    Taking a screenshot of the robot
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]
    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    ${fully_qualified_img_filename}    Set Variable    ${img_folder}${/}${orderid}.png
    Capture Element Screenshot    id:robot-preview-image    ${fully_qualified_img_filename}
    [Return]    ${orderid}    ${fully_qualified_img_filename}


Go to order another robot
    Log To Console    Going to order another robot
    Click Button    id:order-another


Log Out and Close the Browser
    Log To Console    Loging out and closing the browser
    Close Browser


Store the order receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}
    Log To Console    Store the order receipt as a PDF file
    Wait Until Element Is Visible    id:receipt
    Log To Console    Printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    content=${order_receipt_html}    output_path=${pdf_folder}${/}${ORDER_NUMBER}.pdf
    [Return]    ${pdf_folder}${/}${ORDER_NUMBER}.pdf


Embebed the robot screenshot to the receipt PDF file
    Log To Console    Embebing the robor screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Open Pdf    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}:x=0,y=0
    Add Files To Pdf    ${myfiles}    ${PDF_FILE}    ${True}
    Close Pdf    ${PDF_FILE}


Create a ZIP file of receipt PDF files
    Log To Console    Creating a ZIP
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}    recursive=${True}    include=*.pdf
