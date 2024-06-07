import redis
import random
import string

# Function to generate random employee details
def generate_employee():
    name = ''.join(random.choices(string.ascii_uppercase, k=5))
    age = random.randint(20, 60)
    salary = random.randint(30000, 80000)
    return {"name": name, "age": age, "salary": salary}

# Function to add dummy employee data to Redis
def add_dummy_data(redis_host, redis_port, redis_password, num_employees):
    r = redis.Redis(host=redis_host, port=redis_port, password=redis_password)

    for i in range(num_employees):
        employee_id = f"employee:{i}"
        employee_data = generate_employee()
        r.hmset(employee_id, employee_data)

# Main function
def main():
    redis_host = "localhost"
    redis_port = 6379
    redis_password = "redis@123"  # If your Redis server doesn't have a password, set this to None
    num_employees = 100

    add_dummy_data(redis_host, redis_port, redis_password, num_employees)
    print("Dummy employee data added to Redis successfully!")

if __name__ == "__main__":
    main()
