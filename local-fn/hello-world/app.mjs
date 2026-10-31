// A minimal AWS Lambda handler compatible with the SAM local runtime.
export const lambdaHandler = async (event) => {
  const response = {
    statusCode: 200,
    body: JSON.stringify({
      message: "hello world",
    }),
  };

  return response;
};
