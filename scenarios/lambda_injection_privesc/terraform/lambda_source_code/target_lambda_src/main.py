def handler(event, context): 
    return { 
        'message' : "Scenario Completed!"
    }

if __name__ == "__main__":
    print(handler('yo','gurt'))